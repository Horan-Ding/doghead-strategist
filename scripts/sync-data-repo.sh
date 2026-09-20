#!/usr/bin/env bash
# Pull --rebase, commit local text data changes, push. On conflict, exit for AI/manual merge.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -f "$ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.env"
  set +a
fi

DATA_DIR="${GOUTOU_DATA_DIR:-$ROOT/data}"

if [[ ! -d "$DATA_DIR/.git" ]]; then
  echo "Not a git repo: $DATA_DIR"
  echo "Run: ./scripts/bootstrap-data-repo.sh clone|init ..."
  exit 1
fi

cd "$DATA_DIR"
branch="$(git rev-parse --abbrev-ref HEAD)"

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Stashing local changes before pull..."
  git stash push -u -m "sync-data-repo pre-pull $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  stashed=1
else
  stashed=0
fi

if git remote get-url origin &>/dev/null; then
  if ! git pull --rebase origin "$branch"; then
    echo ""
    echo "=== MERGE CONFLICT: resolve in $DATA_DIR, then: ==="
    echo "  git add <resolved-files>"
    echo "  git rebase --continue   # or: git merge --continue"
    echo "  $ROOT/scripts/sync-data-repo.sh"
    echo "Or ask Cursor Agent to merge per docs/private-data-and-sync.md (AI 合成)."
    exit 2
  fi
fi

if [[ "$stashed" == 1 ]]; then
  if ! git stash pop; then
    echo "Stash pop conflict — resolve manually or with AI, then sync again."
    exit 2
  fi
fi

git add -A
if git diff --cached --quiet; then
  echo "No changes to commit in $DATA_DIR"
  exit 0
fi

msg="sync: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
if [[ -n "${SYNC_HOSTNAME:-}" ]]; then
  msg="$msg @${SYNC_HOSTNAME}"
elif command -v hostname >/dev/null; then
  msg="$msg @$(hostname -s 2>/dev/null || hostname)"
fi

git commit -m "$msg"

if git remote get-url origin &>/dev/null; then
  git push origin "$branch"
fi

echo "Synced $DATA_DIR on $branch"
