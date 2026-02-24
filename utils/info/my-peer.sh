#!/bin/bash

# Source the _variables.sh file
. "$(cd "$(dirname "$0")"/.. && pwd)/_variables.sh"

# IP addresss
if [ "$1" = "--local" ]; then
    IP_ADDRESS="127.0.0.1"
else
    IP_ADDRESS=$(curl -s $IP_INFO_PROVIDER)
fi

# Find port of laddr in [p2p] section of config.toml
PORT=$(grep -E "^\[p2p\]" -A 1000 $CONFIG_DIR/config.toml | grep "laddr = " | cut -d':' -f3 | cut -d'"' -f1 | head -n 1)

# Echo node_id@ip_address:port
echo "$($BINARY_NAME tendermint show-node-id)@$IP_ADDRESS:$PORT"