#!/bin/bash

# Migrates configs from v1.1.1 to 1.6.2
# https://github.com/crypto-org-chain/cronos/releases/tag/v1.4.0
# https://github.com/crypto-org-chain/cronos/releases/tag/v1.5.0
# https://github.com/crypto-org-chain/cronos/releases/tag/v1.6.1

set -e
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage:"
  echo "  $0 <config_toml_path> <app_toml_path>"
  exit 1
fi

CONFIG_TOML=$1
APP_TOML=$2

echo ""
echo "Migrating your existing config files...backups (.bak) will be created."
echo "NOTE: New default config comments are not injected during migration."
echo "      For full reference configs, use the config files in the /configs folder or"
echo "      let your upgraded node regenerate the files."

############################################
# TOML helpers
############################################

set_toml_key() {
  local file="$1"
  local section="$2"
  local key="$3"
  local value="$4"
  local mode="${5:-ensure}"  # ensure | exist-only

  # Ensure section exists
  if ! grep -q "^\[$section\]" "$file"; then
    printf "\n[%s]\n" "$section" >> "$file"
  fi

  # Define section range
  local range="/^\[$section\]/,/^\[/"

  if [ "$mode" = "ensure" ]; then

    # If key exists in section → replace it
    if sed -n "$range p" "$file" | grep -q "^$key *="; then
      sed -i "$range s/^$key *= *.*/$key = $value/" "$file"
    else
      # If missing → insert it
      sed -i "/^\[$section\]/a $key = $value" "$file"
    fi

  else
    # exist-only: only add if missing
    sed -n "$range p" "$file" | grep -q "^$key *=" || \
    sed -i "/^\[$section\]/a $key = $value" "$file"
  fi
}

insert_after_key() {
  local file="$1"
  local after_key="$2"
  local key="$3"
  local value="$4"

  # If key already exists anywhere → update it (idempotent behavior)
  if grep -qE "^[[:space:]]*${key}[[:space:]]*=" "$file"; then
    sed -i "s|^[[:space:]]*${key} *=.*|${key} = ${value}|" "$file"
    return 0
  fi

  local line="${key} = ${value}"

  # Insert after anchor key if it exists
  if grep -qE "^[[:space:]]*${after_key}[[:space:]]*=" "$file"; then
    sed -i "/^[[:space:]]*${after_key} *=.*/a ${line}" "$file"
  fi
}

delete_toml_key() {
  local file="$1"
  local section="$2"
  local key="$3"

  local range

  # Sectioned vs global scope
  if [ -n "$section" ]; then
    range="/^\[$section\]/,/^\[/"
  else
    range="1,\$"
  fi

  # Only delete within range
  sed -i "$range {
    /^[[:space:]]*${key}[[:space:]]*=/d
  }" "$file"
}

############################################
# Backup
############################################

cp "$CONFIG_TOML" "$CONFIG_TOML".bak
cp "$APP_TOML" "$APP_TOML".bak

############################################
# CONFIG.TOML
############################################

# add the CometBFT version block at the top.
if ! head -n 50 "$CONFIG_TOML" | grep -qE '^[[:space:]]*version[[:space:]]*='; then
  content=$(cat "$CONFIG_TOML")

  printf '%s\n\n%s' \
'# The version of the CometBFT binary that created or
# last modified the config file. Do not modify this.
version = "0.38.13"' \
"$content" > "$CONFIG_TOML"
fi

# add max_request_batch_size = 10 below timeout_broadcast_tx_commit
insert_after_key "$CONFIG_TOML" "timeout_broadcast_tx_commit" "max_request_batch_size" "10"

# add mempool.recheck_timeout
set_toml_key "$CONFIG_TOML" "mempool" "recheck_timeout" "\"1s\"" ensure

# Remove deprecated block_sync
delete_toml_key "$CONFIG_TOML" "" "block_sync"

# Remove deprecated mempool keys
delete_toml_key "$CONFIG_TOML" "mempool" "version"
delete_toml_key "$CONFIG_TOML" "mempool" "ttl-duration"
delete_toml_key "$CONFIG_TOML" "mempool" "ttl-num-blocks"

############################################
# APP.TOML
############################################

# add mempool.feebump = 10
set_toml_key "$APP_TOML" "versiondb" "enable" "false" ensure

# add telemetry.metrics-sink = ""
set_toml_key "$APP_TOML" "telemetry" "metrics-sink" "\"\"" ensure

# add telemetry.statsd-addr = ""
set_toml_key "$APP_TOML" "telemetry" "statsd-addr" "\"\"" ensure

# add telemetry.datadog-hostname = ""
set_toml_key "$APP_TOML" "telemetry" "datadog-hostname" "\"\"" ensure

# add evm.block-executor = "block-stm"
set_toml_key "$APP_TOML" "evm" "block-executor" "\"block-stm\"" ensure

# add evm.block-stm-workers = 0
set_toml_key "$APP_TOML" "evm" "block-stm-workers" "0" ensure

# add evm.block-stm-pre-estimate = false
set_toml_key "$APP_TOML" "evm" "block-stm-pre-estimate" "false" ensure

# Remove deprecated iavl-lazy-loading
delete_toml_key "$APP_TOML" "" "iavl-lazy-loading"

# Remove deprecated grpc-web.address
delete_toml_key "$APP_TOML" "grpc-web" "address"

# Remove deprecated grpc-web.enable-unsafe-cors
delete_toml_key "$APP_TOML" "grpc-web" "enable-unsafe-cors"

# Remove old store and streamers block
sed -i '/^\[store\]/,/^\[/{ 
  /^\[store\]/d
  /^streamers *= */d
}' "$APP_TOML"

sed -i 's/^\[streamers\]$/[streaming]/' "$APP_TOML"

sed -i 's/^\[streamers\.file\]$/[streaming.abci]/' "$APP_TOML"

# Add new streaming section keys
set_toml_key "$APP_TOML" "streaming.abci" "keys" "[]"
set_toml_key "$APP_TOML" "streaming.abci" "plugin" "\"\""
delete_toml_key "$APP_TOML" "streaming.abci" "stop-node-on-error"
set_toml_key "$APP_TOML" "streaming.abci" "stop-node-on-err" "true"

# add query-gas-limit = 100000000 after minimum-gas-prices
insert_after_key "$APP_TOML" "minimum-gas-prices" "query-gas-limit" "100000000"

# add mempool.feebump = 10
set_toml_key "$APP_TOML" "mempool" "feebump" "10" ensure

# add cronos.disable-tx-replacement = false
set_toml_key "$APP_TOML" "cronos" "disable-tx-replacement" "false" ensure

# add cronos.disable-optimistic-execution = true
set_toml_key "$APP_TOML" "cronos" "disable-optimistic-execution" "true" ensure

############################################
# DONE
############################################

echo ""
echo "Config migration complete!"
echo ""
