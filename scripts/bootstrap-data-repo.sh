#!/usr/bin/env bash
# Create or clone the private goutou-data git repo and wire GOUTOU_DATA_DIR.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEFAULT_TARGET="${HOME}/code/haoran/goutou-data"

usage() {
  cat <<'EOF'
Usage:
  bootstrap-data-repo.sh clone <git-url> [target-dir]
  bootstrap-data-repo.sh init [target-dir]

Examples:
  bootstrap-data-repo.sh clone git@github.com-horan-ding:Horan-Ding/goutou-data.git
  bootstrap-data-repo.sh init ~/code/haoran/goutou-data

After bootstrap, set in doghead-strategist/.env:
  GOUTOU_DATA_DIR="/path/to/goutou-data"
Then run from doghead-strategist:
  ./scripts/init-local-data.sh
EOF
}

cmd="${1:-}"

case "$cmd" in
  clone)
    url="${2:?missing git url}"
    target="${3:-$DEFAULT_TARGET}"
    if [[ -d "$target/.git" ]]; then
      echo "Already a git repo: $target"
      exit 1
    fi
    mkdir -p "$(dirname "$target")"
    git clone "$url" "$target"
    ;;
  init)
    target="${2:-$DEFAULT_TARGET}"
    if [[ -d "$target/.git" ]]; then
      echo "Already a git repo: $target"
      exit 1
    fi
    mkdir -p "$target"
    cp "$ROOT/templates/data-repo/.gitignore" "$target/.gitignore"
    cp "$ROOT/templates/data-repo/README.md" "$target/README.md"
    git -C "$target" init -b main
    ;;
  *)
    usage
    exit 1
    ;;
esac

export GOUTOU_DATA_DIR="$target"
"$ROOT/scripts/init-local-data.sh"

echo ""
echo "Next:"
echo "  1. Add to $ROOT/.env :  GOUTOU_DATA_DIR=\"$target\"  and  GOUTOU_DATA_REPO_URL=<url>"
if [[ "$cmd" == init ]]; then
  echo "  2. Create GitHub private repo (e.g. Horan-Ding/goutou-data), then:"
  echo "     cd \"$target\" && git remote add origin <your-private-repo-url>"
  echo "     git add -A && git commit -m \"init goutou-data\" && git push -u origin main"
fi
echo "  3. Sync: $ROOT/scripts/sync-data-repo.sh"
