package app

import (
	"context"
	"fmt"
	"math/big"
	"time"

	sdkmath "cosmossdk.io/math"
	storetypes "cosmossdk.io/store/types"
	upgradetypes "cosmossdk.io/x/upgrade/types"

	"github.com/cosmos/cosmos-sdk/codec"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/module"
	govkeeper "github.com/cosmos/cosmos-sdk/x/gov/keeper"
	govv1 "github.com/cosmos/cosmos-sdk/x/gov/types/v1"

	icahosttypes "github.com/cosmos/ibc-go/v8/modules/apps/27-interchain-accounts/host/types"

	"github.com/crypto-org-chain/cronos/v2/x/e2ee/types" // e2eetypes
	"github.com/ethereum/go-ethereum/common"
	evmtypes "github.com/evmos/ethermint/x/evm/types"
)

type contractMigration struct {
	Contract common.Address
	Slot     common.Hash
	Value    common.Hash
}

// ContractMigrations records the list of contract migrations, chain-id -> migrations.
// Copied from v1.3.4 upgrade handler.
var ContractMigrations = map[string][]contractMigration{
	"cronostestnet_338-3": {
		{
			Contract: common.HexToAddress("0x6265bf2371ccf45767184c8bd77b5c52e752c2bb"),
			Slot:     common.BigToHash(big.NewInt(0)),
			Value:    common.HexToHash("0x000000000000000000000000730CbB94480d50788481373B43d83133e171367e"),
		},
	},
	"cronosmainnet_25-1": {
		{
			Contract: common.HexToAddress("0x4a91fe94870Ce48fC0bCb7c51d94677E61783401"),
			Slot:     common.BigToHash(big.NewInt(0)),
			Value:    common.HexToHash("0x0000000000000000000000005BD628a417a65DF2320C7a663ccCF38c5d368f38"),
		},
	},
}

// RegisterUpgradeHandlers returns if store loader is overridden.
//
// This version supports a safe jump from v1.1.1 -> v1.6.2 by merging:
// - v1.3: add e2ee store + contract state migrations
// - v1.4: add icahost store + delete icaauth store + param changes + expedited gov params update
// - v1.5: delete capability + feeibc stores
func (app *App) RegisterUpgradeHandlers(cdc codec.BinaryCodec, maxVersion int64) bool {
	planName := "v1.6.2" // keep the canonical plan name if you schedule the chain upgrade as "v1.6"

	app.UpgradeKeeper.SetUpgradeHandler(planName,
		func(ctx context.Context, plan upgradetypes.Plan, fromVM module.VersionMap) (module.VersionMap, error) {
			m, err := app.ModuleManager.RunMigrations(ctx, app.configurator, fromVM)
			if err != nil {
				return m, err
			}

			sdkCtx := sdk.UnwrapSDKContext(ctx)

			// === merged logic from v1.3.4: migrate specific contract states (per chain-id)
			if migrations, ok := ContractMigrations[sdkCtx.ChainID()]; ok {
				for _, migration := range migrations {
					app.EvmKeeper.SetState(sdkCtx, migration.Contract, migration.Slot, migration.Value.Bytes())
				}
			}

			// === merged logic from v1.4.11: disable ICA host, set EVM HeaderHashNum default, update expedited gov params
			{
				params := app.ICAHostKeeper.GetParams(sdkCtx)
				params.HostEnabled = false
				app.ICAHostKeeper.SetParams(sdkCtx, params)

				evmParams := app.EvmKeeper.GetParams(sdkCtx)
				evmParams.HeaderHashNum = evmtypes.DefaultHeaderHashNum
				if err := app.EvmKeeper.SetParams(sdkCtx, evmParams); err != nil {
					return m, err
				}

				if err := UpdateExpeditedParams(ctx, app.GovKeeper); err != nil {
					return m, err
				}
			}

			return m, nil
		},
	)

	upgradeInfo, err := app.UpgradeKeeper.ReadUpgradeInfoFromDisk()
	if err != nil {
		panic(fmt.Sprintf("failed to read upgrade info from disk %s", err))
	}

	if app.UpgradeKeeper.IsSkipHeight(upgradeInfo.Height) {
		return false
	}

	if upgradeInfo.Name != planName {
		return false
	}

	// === merged store loader (v1.3 + v1.4 + v1.5) for a single jump at the v1.6 height
	app.SetStoreLoader(MaxVersionUpgradeStoreLoader(
		maxVersion,
		upgradeInfo.Height,
		&storetypes.StoreUpgrades{
			Added: []string{
				types.StoreKey,         // e2ee (from v1.3)
				icahosttypes.StoreKey,  // icahost (from v1.4)
			},
			Deleted: []string{
				"icaauth",     // deleted in v1.4
				"capability",  // deleted in v1.5
				"feeibc",      // deleted in v1.5
			},
		},
	))

	return true
}

func UpdateExpeditedParams(ctx context.Context, gov govkeeper.Keeper) error {
	govParams, err := gov.Params.Get(ctx)
	if err != nil {
		return err
	}

	if len(govParams.MinDeposit) > 0 {
		minDeposit := govParams.MinDeposit[0]
		expeditedAmount := minDeposit.Amount.MulRaw(govv1.DefaultMinExpeditedDepositTokensRatio)
		govParams.ExpeditedMinDeposit = sdk.NewCoins(sdk.NewCoin(minDeposit.Denom, expeditedAmount))
	}

	threshold, err := sdkmath.LegacyNewDecFromStr(govParams.Threshold)
	if err != nil {
		return fmt.Errorf("invalid threshold string: %w", err)
	}

	expeditedThreshold, err := sdkmath.LegacyNewDecFromStr(govParams.ExpeditedThreshold)
	if err != nil {
		return fmt.Errorf("invalid expedited threshold string: %w", err)
	}

	if expeditedThreshold.LTE(threshold) {
		expeditedThreshold = threshold.Mul(DefaultThresholdRatio())
	}

	if expeditedThreshold.GT(sdkmath.LegacyOneDec()) {
		expeditedThreshold = sdkmath.LegacyOneDec()
	}

	govParams.ExpeditedThreshold = expeditedThreshold.String()

	if govParams.ExpeditedVotingPeriod != nil && govParams.VotingPeriod != nil &&
		*govParams.ExpeditedVotingPeriod >= *govParams.VotingPeriod {

		votingPeriod := DurationToDec(*govParams.VotingPeriod)
		period := DecToDuration(DefaultPeriodRatio().Mul(votingPeriod))
		govParams.ExpeditedVotingPeriod = &period
	}

	if err := govParams.ValidateBasic(); err != nil {
		return err
	}

	return gov.Params.Set(ctx, govParams)
}

func DefaultThresholdRatio() sdkmath.LegacyDec {
	return govv1.DefaultExpeditedThreshold.Quo(govv1.DefaultThreshold)
}

func DefaultPeriodRatio() sdkmath.LegacyDec {
	return DurationToDec(govv1.DefaultExpeditedPeriod).Quo(DurationToDec(govv1.DefaultPeriod))
}

func DurationToDec(d time.Duration) sdkmath.LegacyDec {
	return sdkmath.LegacyMustNewDecFromStr(fmt.Sprintf("%f", d.Seconds()))
}

func DecToDuration(d sdkmath.LegacyDec) time.Duration {
	return time.Second * time.Duration(d.RoundInt64())
}
