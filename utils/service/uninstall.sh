#!/bin/bash

# Source the _variables.sh file
. "$(cd "$(dirname "$0")"/.. && pwd)/_variables.sh"

# Stop service if it exists
systemctl stop $SERVICE_FILE

# Uninstall service
systemctl disable $SERVICE_FILE
rm /etc/systemd/system/$SERVICE_FILE
systemctl daemon-reload