#!/bin/bash

# Source the _variables.sh file
. "$(cd "$(dirname "$0")"/.. && pwd)/_variables.sh"

# Stop service if it exists
systemctl stop $SERVICE_FILE

# Install service
cp $SERVICE_DIR/$SERVICE_FILE /etc/systemd/system/$SERVICE_FILE
systemctl daemon-reload
systemctl enable $SERVICE_FILE