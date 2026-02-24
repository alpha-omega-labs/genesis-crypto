#!/bin/bash

# Arguments check
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: sh $0 <key_alias> <private_eth_key>"
    exit 1
fi

# Source the _variables.sh file
. "$(cd "$(dirname "$0")"/.. && pwd)/_variables.sh"

# Arguments
KEY_ALIAS=$1
PRIVATE_ETH_KEY=$2

# Import key
$BINARY_NAME config keyring-backend os
$BINARY_NAME keys unsafe-import-eth-key $KEY_ALIAS $PRIVATE_ETH_KEY --keyring-backend os