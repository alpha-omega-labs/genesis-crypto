#!/bin/bash

cat <<"EOF"

  /$$$$$$                                          /$$                 /$$         /$$       
 /$$__  $$                                        |__/                | $$       /$$$$       
| $$  \__/  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$ /$$  /$$$$$$$      | $$      |_  $$       
| $$ /$$$$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/| $$ /$$_____/      | $$        | $$       
| $$|_  $$| $$$$$$$$| $$  \ $$| $$$$$$$$|  $$$$$$ | $$|  $$$$$$       | $$        | $$       
| $$  \ $$| $$_____/| $$  | $$| $$_____/ \____  $$| $$ \____  $$      | $$        | $$       
|  $$$$$$/|  $$$$$$$| $$  | $$|  $$$$$$$ /$$$$$$$/| $$ /$$$$$$$/      | $$$$$$$$ /$$$$$$     
 \______/  \_______/|__/  |__/ \_______/|_______/ |__/|_______/       |________/|______/     
                                                                                             
EOF

# Root of the current repository
REPO_ROOT=$(cd "$(dirname "$0")"/.. && pwd)

# Source the variables file
. "$REPO_ROOT/utils/_variables.sh"

echo ""
echo "This script should only be used if your node halted (!) and you have to perform a software upgrade!"
echo "NOTE: a backup of all your important files in $NODE_DIR/ will be created in $NODE_DIR-backup/."
echo ""
read -p "Do you want to continue? (y/N): " ANSWER

ANSWER=$(echo "$ANSWER" | tr 'A-Z' 'a-z')  # Convert to lowercase

if [ "$ANSWER" != "y" ]; then
    echo "Aborted."
    exit 1
fi

# Stop services
systemctl stop $BINARY_NAME

# cd to root of the repository
cd $REPO_ROOT

# System update and installation of dependencies
. ./setup/dependencies.sh

# Backup important files in the node directory
rsync -av --include='data/priv_validator_state.json' --exclude='data/*' "$NODE_DIR/" "$NODE_DIR-backup/"

# Migrate configs
sh ./setup/migrate-configs.sh "$CONFIG_DIR/config.toml" "$CONFIG_DIR/app.toml"

# Install binaries
go mod tidy
make install && {
    echo ""
    echo "Upgrade was a success!"
    echo ""
    echo "When ready, turn on your node again using 'systemctl start $BINARY_NAME'!"
}
