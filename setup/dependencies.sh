#!/bin/bash

# Helper-function: adds a line to a file if it doesn't already exist (to prevent duplicates)
add_line_to_file() {
    local line="$1"
    local file="$2"
    local use_sudo="$3"

    if ! grep -qF "$line" "$file"; then
        if $use_sudo; then
            echo "$line" | sudo tee -a "$file" > /dev/null
        else
            echo "$line" >> "$file"
        fi

        echo "Line '$line' added to $file."
    else
        echo "Line '$line' already exists in $file."
    fi
}

# System update and installation of dependencies
sudo apt-get update -y
sudo apt-get install jq git wget make gcc build-essential snapd -y
snap install go --channel=1.20/stable --classic
snap refresh go --channel=1.20/stable --classic

# Add GOPATH
export PATH=$PATH:$(go env GOPATH)/bin
add_line_to_file 'export PATH=$PATH:$(go env GOPATH)/bin' ~/.bashrc false

# Global change of open file limits
add_line_to_file "* - nofile 50000" /etc/security/limits.conf false
add_line_to_file "root - nofile 50000" /etc/security/limits.conf false
add_line_to_file "fs.file-max = 50000" /etc/sysctl.conf false
ulimit -n 50000
