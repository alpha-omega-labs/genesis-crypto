#!/bin/bash

# Arguments check
if [ -z "$1" ] || [ -z "$2" ]; then
    echo ""
    echo "Usage: sh $0 <moniker> <key_alias>"
    echo ""
    exit 1
fi

cat <<"EOF"

  /$$$$$$                                          /$$                 /$$         /$$       
 /$$__  $$                                        |__/                | $$       /$$$$       
| $$  \__/  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$ /$$  /$$$$$$$      | $$      |_  $$       
| $$ /$$$$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/| $$ /$$_____/      | $$        | $$       
| $$|_  $$| $$$$$$$$| $$  \ $$| $$$$$$$$|  $$$$$$ | $$|  $$$$$$       | $$        | $$       
| $$  \ $$| $$_____/| $$  | $$| $$_____/ \____  $$| $$ \____  $$      | $$        | $$       
|  $$$$$$/|  $$$$$$$| $$  | $$|  $$$$$$$ /$$$$$$$/| $$ /$$$$$$$/      | $$$$$$$$ /$$$$$$     
 \______/  \_______/|__/  |__/ \_______/|_______/ |__/|_______/       |________/|______/     
                                                                                             
Welcome to the decentralized blockchain Renaissance, above money & beyond cryptocurrency!
EOF

echo ""
echo "Creating a validator should only be done if your node is all caught up (at the latest"
echo "height) and you've generated or imported a key. In the /utils-folder you can find two"
echo "scripts making it easier to either create a key or import one using a private key."
echo ""
echo "If you're all set, then you can proceed."
read -p "Ready? (y/N): " ANSWER

ANSWER=$(echo "$ANSWER" | tr 'A-Z' 'a-z')  # Convert to lowercase

if [ "$ANSWER" != "y" ]; then
    echo "Aborted."
    exit 1
fi

# Root of the current repository
REPO_ROOT=$(cd "$(dirname "$0")"/.. && pwd)

# Source the variables file
. "$REPO_ROOT/utils/_variables.sh"

# Arguments
MONIKER=$1
KEY_ALIAS=$2

# Set default values
DEFAULT_AMOUNT=1
DEFAULT_COMMISSION_RATE=0.05
DEFAULT_COMMISSION_MAX_RATE=0.99
DEFAULT_COMMISSION_MAX_CHANGE_RATE=0.01
DEFAULT_MINIMUM_SELF_DELEGATION=1000000
DECIMALS="000000000000000000"
DEFAULT_FEES="210000000000000000000"

# Read optional user inputs
read -p "What's the amount you'll self-delegate? (denom: L1) [default: $DEFAULT_AMOUNT]: " AMOUNT
AMOUNT=${AMOUNT:-$DEFAULT_AMOUNT}
read -p "What will be your commission rate percentage? (default: $DEFAULT_COMMISSION_RATE): " COMMISSION_RATE
COMMISSION_RATE=${COMMISSION_RATE:-$DEFAULT_COMMISSION_RATE}
read -p "What will be your max commission rate percentage? (default: $DEFAULT_COMMISSION_MAX_RATE): " COMMISSION_MAX_RATE
COMMISSION_MAX_RATE=${COMMISSION_MAX_RATE:-$DEFAULT_COMMISSION_MAX_RATE}
read -p "What will be your max commission change rate percentage per day? (default: $DEFAULT_COMMISSION_MAX_CHANGE_RATE): " COMMISSION_MAX_CHANGE_RATE
COMMISSION_MAX_CHANGE_RATE=${COMMISSION_MAX_CHANGE_RATE:-$DEFAULT_COMMISSION_MAX_CHANGE_RATE}
read -p "What will be your minimum self delegation? (denom: el1) [default: $DEFAULT_MINIMUM_SELF_DELEGATION]: " MINIMUM_SELF_DELEGATION
MINIMUM_SELF_DELEGATION=${MINIMUM_SELF_DELEGATION:-$DEFAULT_MINIMUM_SELF_DELEGATION}
read -p "What will you set for gas fees? (denom: el1) [default: $DEFAULT_FEES]: " FEES
FEES=${FEES:-$DEFAULT_FEES}

COMMAND_TO_EXECUTE="$BINARY_NAME tx staking create-validator \
--amount "$AMOUNT$DECIMALS"el1 \
--pubkey '$($BINARY_NAME tendermint show-validator)' \
--moniker "$MONIKER" \
--chain-id "$CHAIN_ID" \
--commission-rate "$COMMISSION_RATE" \
--commission-max-rate "$COMMISSION_MAX_RATE" \
--commission-max-change-rate "$COMMISSION_MAX_CHANGE_RATE" \
--min-self-delegation "$MINIMUM_SELF_DELEGATION" \
--gas "2200000" \
--from "$KEY_ALIAS" \
--fees "$FEES"el1 \
-y"

echo ""
echo "will execute: $COMMAND_TO_EXECUTE"
eval "$COMMAND_TO_EXECUTE"