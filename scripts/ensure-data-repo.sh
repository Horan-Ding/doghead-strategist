#!/usr/bin/env bash
# Ensure GOUTOU_DATA_DIR exists as a clone of the private goutou-data repo; pull latest.
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
  branch="$(git -C "$DATA_DIR" rev-parse --abbrev-ref HEAD)"
  git -C "$DATA_DIR" pull --rebase origin "$branch" || {
    echo "Pull failed — resolve conflicts in $DATA_DIR or run sync after merge."
    exit 2
  }
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
