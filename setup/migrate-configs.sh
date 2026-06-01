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
# TOML helper
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

############################################
# Backup
############################################

cp "$CONFIG_TOML" "$CONFIG_TOML".bak
cp "$APP_TOML" "$APP_TOML".bak

############################################
# CONFIG.TOML
############################################

# Rename fast_sync -> block_sync
sed -i 's/^fast_sync *= */block_sync = /' "$CONFIG_TOML"

# Rename [fastsync] -> [blocksync]
sed -i 's/^\[fastsync\]/[blocksync]/' "$CONFIG_TOML"

# Remove deprecated p2p.upnp
sed -i '/^\[p2p\]/,/^\[/ {
  /^upnp *= */d
}' "$CONFIG_TOML"

# mempool type enforced
set_toml_key "$CONFIG_TOML" "mempool" "type" "\"flood\"" ensure

# experimental peers (exist-only)
set_toml_key "$CONFIG_TOML" "mempool" "experimental_max_gossip_connections_to_persistent_peers" "0" exist-only
set_toml_key "$CONFIG_TOML" "mempool" "experimental_max_gossip_connections_to_non_persistent_peers" "0" exist-only

############################################
# APP.TOML
############################################

# mempool max txs (ensure value)
set_toml_key "$APP_TOML" "mempool" "max-txs" "5000" ensure

# json-rpc settings (ensure values)
set_toml_key "$APP_TOML" "json-rpc" "allow-indexer-gap" "true" ensure
set_toml_key "$APP_TOML" "json-rpc" "return-data-limit" "100000" ensure

############################################
# DONE
############################################

echo ""
echo "Config migration complete!"
echo ""
