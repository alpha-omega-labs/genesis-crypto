#!/bin/bash

# Source the _variables.sh file
. "$(cd "$(dirname "$0")"/.. && pwd)/_variables.sh"

# Fetch genesis.json
wget -qO "$CONFIG_DIR/genesis.json" $STATE_URL

# Echo result
echo "Added genesis.json file to $CONFIG_DIR"