#!/bin/bash

# Source the _variables.sh file
. "$(cd "$(dirname "$0")"/.. && pwd)/_variables.sh"

# Fetch latest rpc_servers
RPC_SERVERS=$(wget -qO - $RPC_SERVERS_URL | head -n 1)

if [ -z "$RPC_SERVERS" ] || [ "$RPC_SERVERS" = '""' ]; then
    # Echo result
    echo "No rpc_servers found."
else
    # Add latest rpc_servers to the config.toml file
    sed -i "s#rpc_servers = .*#rpc_servers = $RPC_SERVERS#" "$CONFIG_DIR/config.toml"

    # Echo result
    echo "Added rpc_servers = $RPC_SERVERS"
fi