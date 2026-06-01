#!/usr/bin/env bash
set -euo pipefail

# Recover specific Cronos upstream tags in this local clone.
# Usage:
#   ./scripts/recover-cronos-tags.sh
#   ./scripts/recover-cronos-tags.sh v1.5.4 v1.6.2

TARGET_TAGS=("${@:-}")
if [ ${#TARGET_TAGS[@]} -eq 0 ]; then
  TARGET_TAGS=(v1.1.1 v1.2.2 v1.3.4 v1.4.11 v1.5.4 v1.6.2)
fi

REMOTE_NAME="cronos"
REMOTE_URL="https://github.com/crypto-org-chain/cronos.git"

if ! git remote get-url "$REMOTE_NAME" >/dev/null 2>&1; then
  git remote add "$REMOTE_NAME" "$REMOTE_URL"
fi

echo "Using remote '$REMOTE_NAME' -> $(git remote get-url "$REMOTE_NAME")"

echo "Checking remote connectivity..."
if ! git ls-remote "$REMOTE_NAME" >/dev/null 2>&1; then
  echo "ERROR: unable to reach remote '$REMOTE_NAME'."
  echo "Hint: verify outbound network/proxy access to github.com, then rerun."
  exit 2
fi

for tag in "${TARGET_TAGS[@]}"; do
  echo "\n==> recovering tag: $tag"
  if git rev-parse -q --verify "refs/tags/$tag" >/dev/null 2>&1; then
    echo "  already present locally"
    continue
  fi

  if git ls-remote --tags "$REMOTE_NAME" "refs/tags/$tag" | grep -q .; then
    git fetch "$REMOTE_NAME" "refs/tags/$tag:refs/tags/$tag"
    echo "  imported $tag"
  else
    echo "  NOT FOUND on remote: $tag"
  fi

done

echo "\nRecovered tags now available locally:"
for tag in "${TARGET_TAGS[@]}"; do
  if git rev-parse -q --verify "refs/tags/$tag" >/dev/null 2>&1; then
    printf "  - %s -> %s\n" "$tag" "$(git rev-list -n 1 "$tag")"
  fi
done
