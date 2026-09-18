#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="${GOUTOU_DATA_DIR:-$ROOT/data}"

mkdir -p "$DATA_DIR/me"
mkdir -p "$DATA_DIR/people"
mkdir -p "$DATA_DIR/sessions"

if [[ ! -f "$DATA_DIR/config.yaml" ]]; then
  cp "$ROOT/templates/data/config.yaml" "$DATA_DIR/config.yaml"
fi

if [[ ! -f "$DATA_DIR/me/profile.yaml" ]]; then
  cp "$ROOT/templates/me/profile.yaml" "$DATA_DIR/me/profile.yaml"
fi

echo "Initialized private data at: $DATA_DIR"
echo "Copy examples/people/demo-alice into data/people/ to try locally, or add a new codename folder."
