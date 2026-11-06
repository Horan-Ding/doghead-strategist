#!/usr/bin/env bash
# One sync attempt. Local saves do not invoke this; the scheduler or user does.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -f "$ROOT/.env" ]]; then
  set -a
  source "$ROOT/.env"
  set +a
fi
cd "${GOUTOU_DATA_DIR:-$ROOT/data}"
git rev-parse --git-dir >/dev/null
# Writers use the same lock around their read/modify/write operation.
exec 9>"$(git rev-parse --git-path goutou-sync.lock)"
flock -n 9 || { echo 'Busy: data write or sync in progress; retry later.'; exit 75; }
if [[ -d "$(git rev-parse --git-path rebase-merge)" || -d "$(git rev-parse --git-path rebase-apply)" || -f "$(git rev-parse --git-path MERGE_HEAD)" ]] || [[ -n "$(git ls-files -u)" ]]; then
  echo 'Unresolved merge/rebase: resolve manually before syncing.'
  exit 2
fi
branch="$(git symbolic-ref --quiet --short HEAD)" || { echo 'Detached HEAD: choose the intended data branch first.'; exit 1; }
remote_branch="${GOUTOU_DATA_BRANCH:-$branch}"
git check-ref-format "refs/heads/$remote_branch"
# Commit first: failed network requests leave all edits visible in local history.
git add -A
if ! git diff --cached --quiet; then
  git commit -m "sync: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
fi
if ! git remote get-url origin >/dev/null 2>&1; then
  echo 'Saved locally; origin is not configured, so remote sync did not run.'
  exit 1
fi
export GIT_TERMINAL_PROMPT=0
if ! git -c http.lowSpeedLimit=1 -c http.lowSpeedTime=30 fetch origin "refs/heads/$remote_branch"; then
  echo 'Fetch failed; local commits retained. Retry when the remote is available.'
  exit 1
fi
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo 'Files changed during sync; retry later. Writers must use goutou-sync.lock.'
  exit 75
fi
if ! git rebase FETCH_HEAD; then
  if [[ -d "$(git rev-parse --git-path rebase-merge)" || -d "$(git rev-parse --git-path rebase-apply)" ]]; then
    echo 'Rebase conflict: resolve or abort manually; automatic sync will pause.'
    exit 2
  fi
  echo 'Rebase failed; inspect local files before retrying.'
  exit 1
fi
# Also push previously committed work after an earlier push failure.
if [[ "$(git rev-parse HEAD)" != "$(git rev-parse FETCH_HEAD)" ]]; then
  if ! git -c http.lowSpeedLimit=1 -c http.lowSpeedTime=30 push origin "HEAD:refs/heads/$remote_branch"; then
    echo 'Push failed; local commits retained for the next attempt.'
    exit 1
  fi
fi
echo "Synced origin/$remote_branch."
