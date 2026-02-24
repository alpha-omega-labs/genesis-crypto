#!/bin/bash

# Source the _variables.sh file
. "$(cd "$(dirname "$0")"/.. && pwd)/_variables.sh"

# Node directory check
if [ ! -e "$NODE_DIR" ]; then
    echo "No backup can be made for $NODE_DIR doesn't exist!"
    exit 1
fi

# Arguments
BACKUP_DIR=${1:-$HOME/""$NODE_DIR_NAME"_backup_$(date +"%Y%m%d%H%M%S")"}

# Information prompt
echo "This script will halt $BINARY_NAME and backup the $NODE_DIR folder."
echo ""
echo "    o Backup directory is set to: $BACKUP_DIR."
if [ -z $1 ]; then
    echo "      This can be changed using: sh $0 [backup_dir]"
fi
echo ""
echo "If you continue, you'll be asked whether you'd want to back-up the entire"
echo "/data folder. The choice you make won't decide whether priv_validator_state.json"
echo "gets backed up or not, as this will always be performed."
echo ""
read -p "Do you want to continue? (y/N): " ANSWER

ANSWER=$(echo "$ANSWER" | tr 'A-Z' 'a-z')  # Convert to lowercase

if [ "$ANSWER" != "y" ]; then
    echo "Aborted."
    exit 1
fi

# Preserve database prompt
read -p "Do you also want to backup the database (entire /data folder)? (y/N): " PRESERVE

PRESERVE=$(echo "$PRESERVE" | tr 'A-Z' 'a-z')  # Convert to lowercase

if [ "$PRESERVE" = "y" ]; then
    PRESERVE_DB=true
    read -p "Do you want to perform the /data backup with a copy or move operation? (c/M): " COPY_MOVE
    COPY_MOVE=$(echo "$COPY_MOVE" | tr 'A-Z' 'a-z')  # Convert to lowercase
else
    PRESERVE_DB=false
fi

# Stop processes
systemctl stop $BINARY_NAME

# Backup of previous configuration if one existed
rsync -qr --verbose --exclude 'data' --exclude 'config/genesis.json' "$NODE_DIR"/ "$BACKUP_DIR"/

# Remake /data folder
rm -r "$BACKUP_DIR"/data > /dev/null 2>&1
mkdir -p "$BACKUP_DIR"/data

# Perform /data folder operations
if $PRESERVE_DB; then
    if [ "$COPY_MOVE" = "c" ]; then
        if cp -r $DATA_DIR "$BACKUP_DIR"/; then
            echo "Backed up entire /data folder with a cp-operation."
        fi
    else
        if mv $DATA_DIR "$BACKUP_DIR"/; then
            echo "Backed up entire /data folder with a mv-operation."
        fi
    fi
else
    if cp "$DATA_DIR"/priv_validator_state.json "$BACKUP_DIR"/data/priv_validator_state.json; then
        echo "Backed up previous priv_validator_state.json file."
    fi
fi

# Echo result
echo "$NODE_DIR was backed up to to $BACKUP_DIR."