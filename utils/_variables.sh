#!/bin/bash

# Variables for all modules
CHAIN_ID=genesis_29-2
BINARY_NAME=genesisd
NODE_DIR_NAME=.genesis
NODE_DIR=$HOME/$NODE_DIR_NAME
CONFIG_DIR=$NODE_DIR/config
DATA_DIR=$NODE_DIR/data

# /fetch module variables.
FETCH_URL=https://raw.githubusercontent.com/alpha-omega-labs/genesis-parameters/main/$CHAIN_ID
SEEDS_URL=$FETCH_URL/seeds.txt
PEERS_URL=$FETCH_URL/peers.txt
STATE_URL=$FETCH_URL/genesis.json
RPC_SERVERS_URL=$FETCH_URL/rpc_servers.txt

# /info module variables.
IP_INFO_PROVIDER=ipinfo.io/ip

# /service module variables.
SERVICE_DIR=$(cd "$(dirname "$0")"/../.. && pwd)/services
SERVICE_FILE=$BINARY_NAME.service
