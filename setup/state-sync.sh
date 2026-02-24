#!/bin/bash

# Arguments check
if [ -z "$1" ]; then
    echo ""
    echo "Usage: sh $0 <moniker>"
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
echo "This script is intended for those who would like to join the mainnet using State Sync."
echo "State Sync allows a node to join a network in a matter of minutes/hours, without having"
echo "to worry about needing a lot of free disk space."
echo ""
echo "While this is favorable for the individual validator, it isn't necessarly from a broader"
echo "network perspective since you do not have the entire history of the blockchain recorded."
echo "So take this into consideration when deciding to state sync or not."
echo ""
echo "WARNING: Any config files will get overwritten and the data folder shall be removed, but there"
echo "will be a backup and restore of the priv_validator_state.json file. If needed, use"
echo "utils/backup/create.sh to create a backup."
echo ""
read -p "Do you want to continue? (y/N): " ANSWER

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

# Stop processes
systemctl stop $BINARY_NAME

# cd to root of the repository
cd $REPO_ROOT

# System update and installation of dependencies
. ./setup/dependencies.sh

# Building binaries
go mod tidy
make install

# Set chain-id
$BINARY_NAME config chain-id $CHAIN_ID

# Init node
$BINARY_NAME init $MONIKER --chain-id $CHAIN_ID -o

# Chain specific configurations (i.e. timeout_commit 10s, min gas price 50gel)
cp "./configs/default_app.toml" $CONFIG_DIR/app.toml
cp "./configs/default_config.toml" $CONFIG_DIR/config.toml
# Set moniker again since the configs got overwritten
sed -i "s/moniker = .*/moniker = \"$MONIKER\"/" $CONFIG_DIR/config.toml

# Fetch latest seeds and peers list from genesis-parameters repo
sh ./utils/fetch/peers.sh

# Fetch state file from genesis-parameters repo
sh ./utils/fetch/state.sh

# Fetch latest rpc_servers from genesis-parameters repo
sh ./utils/fetch/rpcs.sh

# Install service (commented out)
# sh ./utils/service/install.sh

# Recalibrate state sync
if sh ./utils/tools/restate-sync.sh; then
    echo ""
    echo "PS: if you're unable to access the $BINARY_NAME command, run '. ~/.bashrc' or 'source ~/.bashrc'."
    echo "Optional: use utils/service/install.sh to install the node as a service (will be named $BINARY_NAME)."
fi
