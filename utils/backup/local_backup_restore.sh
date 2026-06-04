#!/usr/bin/env bash
# local_backup_restore.sh
#
# Restore a GenesisL1/Cosmos-style snapshot from a local .tar.lz4 file into ~/.genesis.
# Expectation: the archive contains a top-level "data/" directory.
#
# Validator safety:
#   By default, this script preserves existing data/priv_validator_state.json.
#   This helps avoid double-sign/slashing risk when restoring on a validator.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  local_backup_restore.sh -i /path/to/data_snapshot.tar.lz4 [options]

Required:
  -i, --input FILE             Path to local .tar.lz4 snapshot file

Options:
  -H, --home-dir DIR           Genesis home directory (default: $HOME/.genesis)
  -d, --daemon NAME            Systemd service to stop/start (default: genesisd)
  -s, --stop-start             Stop daemon before restore and start after
  -r, --remove-existing        Remove existing "data/" before restore
  -n, --dry-run                Print what would be done, no changes

Validator state options:
      --keep-validator-state   Preserve existing data/priv_validator_state.json (default)
      --no-keep-validator-state
                               Use snapshot's priv_validator_state.json instead

  -h, --help                   Show this help

Examples:
  ./local_backup_restore.sh -i /mnt/backup/data_13002000.tar.lz4
  ./local_backup_restore.sh -i ./data_13002000.tar.lz4 -s -r
  ./local_backup_restore.sh -i ./data_13002000.tar.lz4 -H /srv/genesis/.genesis -s -d genesisd
  ./local_backup_restore.sh -i ./data_13002000.tar.lz4 -s -r --no-keep-validator-state
EOF
}

INPUT=""
HOME_DIR="${HOME}/.genesis"
DAEMON="genesisd"
DO_STOP_START=0
REMOVE_EXISTING=0
DRY_RUN=0
KEEP_VALIDATOR_STATE=1

require_value() {
  local flag="$1"
  local value="${2:-}"
  if [[ -z "$value" ]]; then
    echo "ERROR: ${flag} requires a value" >&2
    usage
    exit 2
  fi
}

quote_cmd() {
  printf '%q ' "$@"
}

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] $(quote_cmd "$@")"
  else
    "$@"
  fi
}

# --- args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--input)
      require_value "$1" "${2:-}"
      INPUT="$2"
      shift 2
      ;;
    -H|--home-dir)
      require_value "$1" "${2:-}"
      HOME_DIR="$2"
      shift 2
      ;;
    -d|--daemon)
      require_value "$1" "${2:-}"
      DAEMON="$2"
      shift 2
      ;;
    -s|--stop-start)
      DO_STOP_START=1
      shift
      ;;
    -r|--remove-existing)
      REMOVE_EXISTING=1
      shift
      ;;
    -n|--dry-run)
      DRY_RUN=1
      shift
      ;;
    --keep-validator-state)
      KEEP_VALIDATOR_STATE=1
      shift
      ;;
    --no-keep-validator-state)
      KEEP_VALIDATOR_STATE=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 2
      ;;
  esac
done

# --- checks ---
if [[ -z "$INPUT" ]]; then
  echo "ERROR: --input is required" >&2
  usage
  exit 2
fi

if [[ ! -f "$INPUT" ]]; then
  echo "ERROR: input file not found: $INPUT" >&2
  exit 2
fi

command -v lz4 >/dev/null 2>&1 || {
  echo "ERROR: lz4 not found in PATH" >&2
  exit 127
}

command -v tar >/dev/null 2>&1 || {
  echo "ERROR: tar not found in PATH" >&2
  exit 127
}

if [[ "$DO_STOP_START" -eq 1 ]]; then
  command -v systemctl >/dev/null 2>&1 || {
    echo "ERROR: systemctl not found in PATH" >&2
    exit 127
  }
fi

PVS="${HOME_DIR}/data/priv_validator_state.json"
PVS_BACKUP=""

echo "==> Restoring FULL data folder snapshot from local archive"
echo "    input                 : ${INPUT}"
echo "    home-dir              : ${HOME_DIR}"
echo "    daemon                : ${DAEMON}"
echo "    stop/start            : ${DO_STOP_START}"
echo "    rm data/              : ${REMOVE_EXISTING}"
echo "    keep validator state  : ${KEEP_VALIDATOR_STATE}"
echo

run mkdir -p "$HOME_DIR"

if [[ "$DO_STOP_START" -eq 1 ]]; then
  run systemctl stop "$DAEMON"
fi

# Preserve validator signing state before wiping/extracting.
if [[ "$KEEP_VALIDATOR_STATE" -eq 1 ]]; then
  if [[ -f "$PVS" ]]; then
    PVS_BACKUP="${HOME_DIR}/priv_validator_state.$(date -u +%Y%m%dT%H%M%SZ).bak.json"
    echo "==> Preserving validator signing state"
    echo "    from: ${PVS}"
    echo "    to  : ${PVS_BACKUP}"
    run cp -a "$PVS" "$PVS_BACKUP"
    echo
  else
    echo "==> No existing priv_validator_state.json found to preserve"
    echo "    If this is a validator, make sure this is intentional."
    echo
  fi
else
  echo "WARNING: --no-keep-validator-state selected."
  echo "         The snapshot's priv_validator_state.json will be used if present."
  echo "         Do NOT use this on a validator unless you know it is safe."
  echo
fi

if [[ "$REMOVE_EXISTING" -eq 1 ]]; then
  run rm -rf "${HOME_DIR}/data"
fi

# Sanity check without grep/head SIGPIPE causing a false warning under pipefail.
if [[ "$DRY_RUN" -eq 0 ]]; then
  echo "==> Checking archive contains top-level 'data/' ..."
  listing="$(lz4 -dc "$INPUT" 2>/dev/null | tar -tf - 2>/dev/null | head -n 50 || true)"

  if ! grep -qE '^data/' <<<"$listing"; then
    echo "WARNING: Could not confirm 'data/' at archive root from the first entries." >&2
    echo "         If your tar stores 'data/' later, this warning can be ignored." >&2
  fi
  echo
fi

echo "==> Extracting into ${HOME_DIR} ..."
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[dry-run] lz4 -dc $(printf '%q' "$INPUT") | tar -xvf - -C $(printf '%q' "$HOME_DIR")"
else
  lz4 -dc "$INPUT" | tar -xvf - -C "$HOME_DIR"
fi
echo

# Restore preserved validator signing state after snapshot extraction.
if [[ "$KEEP_VALIDATOR_STATE" -eq 1 && -n "$PVS_BACKUP" ]]; then
  echo "==> Restoring preserved validator signing state"
  run mkdir -p "$(dirname "$PVS")"
  run mv -f "$PVS_BACKUP" "$PVS"
  echo
fi

if [[ "$DO_STOP_START" -eq 1 ]]; then
  run systemctl start "$DAEMON"
fi

echo "==> Done."
