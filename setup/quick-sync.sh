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
echo "This script should only be used if you intend on bootstrapping a snapshot of the GenesisL1 mainnet."
echo "This will not take care of any backups! So make sure to do this if you have an existing .genesis"
echo "folder already. You can use utils/backup/create.sh for this."
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

# Stop processes (if any are running)
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

# Fetch state file from genesis-parameters repo
sh ./utils/fetch/state.sh

# Fetch latest seeds and peers list from genesis-parameters repo
sh ./utils/fetch/peers.sh

# Reset to imported genesis.json (commented out)
# $BINARY_NAME tendermint unsafe-reset-all

# Install service (commented out)
# sh ./utils/service/install.sh

# Echo result
echo ""
echo "Done!"
echo ""
echo "o Check if you're able to access the $BINARY_NAME command. If you can't, run '. ~/.bashrc' or 'source ~/.bashrc' in your terminal. Then, proceed bootstrapping the snapshot via the steps provided in the README."
echo "o If you haven't already created a key, use utils/key/create.sh or utils/key/import.sh to create or import a private key."
echo "o Optional: use utils/service/install.sh to install the node as a service (will be named $BINARY_NAME)."
echo "o When ready, turn on your node using '$BINARY_NAME start' or as a service: 'systemctl start $BINARY_NAME' (use 'journalctl -fu $BINARY_NAME -ocat' to see the service logs)."
