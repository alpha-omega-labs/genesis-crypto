# Setup

## dependencies.sh

This script installs all the dependencies (and system configurations) that are necessary for the binary to run. Since this file already gets called from within the other scripts, it is not required to call this yourself.

## upgrade.sh

> [!WARNING]
> This script is release-dependent. See [README.md](/README.md) to see which version you have to use.
>

This version of the script takes care of the following to upgrade your node:

- It stops the node (the service)
- Installs or upgrades all the necessary dependencies
- Creates a backup of existing _config.toml_ or _app.toml_ files (as _.toml.bak_)
- Calls [migrate-configs.sh](/setup/migrate-configs.sh) to migrate your app.toml and config.toml files
- Builds the binaries

### Usage

```
sh setup/upgrade.sh
```
> After a successful upgrade, start the node again using `systemctl start genesisd` and monitor its status with `journalctl -fu genesisd -ocat`.


### migrate-configs.sh

> [!WARNING]
> This script gets called automatically if you use the upgrade.sh script and is also release-dependent.
>

This version of the script takes care of the following:
- Applies the config changes as detailed in https://github.com/crypto-org-chain/cronos/releases/tag/v1.4.0,
- https://github.com/crypto-org-chain/cronos/releases/tag/v1.5.0, and
- https://github.com/crypto-org-chain/cronos/releases/tag/v1.6.1.

### Usage

```
sh setup/migrate-configs.sh <config_toml_path> <app_toml_path>
```

## staged-upgrade.sh

> [!WARNING]
> This script is release-dependent. Use the correct upgrade name, version, height and commit for the target release.
>

This script prepares the upgrade before the chain reaches the upgrade height, then applies it automatically after the node halts.

This version of the script takes care of the following to upgrade your node:

- Clones the required upgrade version while the old node is still running
- Checks out the configured upgrade tag or commit
- Builds the new `genesisd` binary in a separate staging directory
- Waits until the configured upgrade height is reached and the node halts
- Stops the node service
- Creates a backup of important validator files and configs
- Calls [migrate-configs.sh](/setup/migrate-configs.sh) to migrate your app.toml and config.toml files
- Replaces the old binary with the pre-built upgraded binary
- Starts the node service again

### Usage

```
UPGRADE_NAME=v1.1.1 \
UPGRADE_REF=v1.1.1 \
UPGRADE_HEIGHT=13000000 \
EXPECTED_COMMIT=bab909493ad4f56828b5ee30c21c97219fbb93c1 \
bash setup/staged-upgrade.sh
```

> The script does **not** replace the running binary before the upgrade height.
>
> It only prepares the new binary in advance, then installs it after the node has halted for the upgrade.
>
> It is recommended to run this script inside `tmux` or `screen`, so it keeps running if your SSH session disconnects.

## quick-sync.sh

> [!CAUTION]
> Running this will **wipe the entire database** (the _/data_-folder **excluding** the priv_validator_state.json file).
>
> Make a backup if needed: [utils/backup/create.sh](/utils/backup/create.sh).

As the name suggests, this script should be used to quick-sync a node:

- It stops the service (if it exists)
- Installs all the necessary dependencies
- Builds the binaries
- Resets config files
- Fetches state, seeds and peers
- Initializes the node

### Usage

```
sh setup/quick-sync.sh <moniker>
```
> If you can't access the `genesisd` command afterwards, execute the `. ~/.bashrc` _or_ `source ~/.bashrc` command in your terminal.
>
> **IMPORTANT:** currently, snapshots must be bootstrapped manually. Please refer to the main [README](/README.md) for further instructions.

## create-validator.sh

> [!IMPORTANT]
> _create-validator.sh_ requires a key.
>
> If you haven't already created or imported one, use: [utils/key/create.sh](/utils/key/create.sh) _or_ [utils/key/import.sh](/utils/key/import.sh).

This script should only be run once you're **fully synced**. It's a wizard; prompting the user only the required fields for creating a validator.

### Usage

```
sh setup/create-validator.sh <moniker> <key_alias>
```
