#!/usr/bin/env bash
# Ensure GOUTOU_DATA_DIR exists. Existing checkouts sync on the schedule.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -f "$ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.env"
  set +a
fi

REPO_URL="${GOUTOU_DATA_REPO_URL:-}"
DATA_DIR="${GOUTOU_DATA_DIR:-$ROOT/data}"

if [[ -z "$REPO_URL" ]]; then
  echo "Set GOUTOU_DATA_REPO_URL in $ROOT/.env (see .env.example)."
  exit 1
fi

if [[ -d "$DATA_DIR/.git" ]]; then
  echo "Data repo present: $DATA_DIR"
  # Existing data is used locally; explicit refresh uses sync-data-repo.sh.

elif [[ -d "$DATA_DIR" ]] && [[ -n "$(ls -A "$DATA_DIR" 2>/dev/null || true)" ]]; then
  echo "Directory exists but is not a git repo: $DATA_DIR"
  echo "Move it aside, then re-run this script to clone."
  exit 1
else
  mkdir -p "$(dirname "$DATA_DIR")"
  git clone "$REPO_URL" "$DATA_DIR"
fi

export GOUTOU_DATA_DIR="$DATA_DIR"
"$ROOT/scripts/init-local-data.sh"
echo "GOUTOU_DATA_DIR=$DATA_DIR"
