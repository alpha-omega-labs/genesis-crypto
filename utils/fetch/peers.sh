#!/bin/bash

# Source the _variables.sh file
. "$(cd "$(dirname "$0")"/.. && pwd)/_variables.sh"

# Fetch latest seeds and peers
SEEDS=$(wget -qO - $SEEDS_URL | head -n 1)
PERSISTENT_PEERS=$(wget -qO - $PEERS_URL | head -n 1)

# Add latest seeds and peers to the config.toml file
sed -i "s#seeds = .*#seeds = $SEEDS#" "$CONFIG_DIR/config.toml"
sed -i "s#persistent_peers = .*#persistent_peers = $PERSISTENT_PEERS#" "$CONFIG_DIR/config.toml"

# Echo result
echo "Added seeds = $SEEDS"
echo "Added persistent_peers = $PERSISTENT_PEERS"