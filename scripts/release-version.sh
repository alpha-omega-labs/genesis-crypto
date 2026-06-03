#!/bin/bash
set -e

# Root of the current repository
REPO_ROOT=$(cd "$(dirname "$0")"/.. && pwd)

# Build release
GITHUB_REF_NAME=$1 "$REPO_ROOT/scripts/release.sh"

# Generate checksums
cd "$REPO_ROOT"
sha256sum *.tar.gz > checksums.txt