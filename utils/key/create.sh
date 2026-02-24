#!/bin/bash

# Arguments check
if [ -z "$1" ]; then
    echo "Usage: sh $0 <key_alias>"
    exit 1
fi

# Source the _variables.sh file
. "$(cd "$(dirname "$0")"/.. && pwd)/_variables.sh"

# Arguments
KEY_ALIAS=$1

# Create key
$BINARY_NAME config keyring-backend os
$BINARY_NAME keys add $KEY_ALIAS --keyring-backend os --algo eth_secp256k1