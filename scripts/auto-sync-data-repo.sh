#!/usr/bin/env bash
# Linux background scheduler; no cron daemon required.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -f "$ROOT/.env" ]]; then
  set -a
  source "$ROOT/.env"
  set +a
fi
STATE="$ROOT/.goutou/auto-sync"
mkdir -p "$STATE"
chmod 700 "$STATE"
interval="${GOUTOU_SYNC_INTERVAL_SECONDS:-600}"
[[ "$interval" =~ ^[1-9][0-9]*$ ]] || { echo 'Interval must be a positive integer in seconds.'; exit 1; }
is_running() {
  [[ -f "$STATE/pid" ]] || return 1
  read -r pid < "$STATE/pid"
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  kill -0 "$pid" 2>/dev/null && [[ "$(ps -p "$pid" -o args=)" == *"$ROOT/scripts/auto-sync-data-repo.sh run"* ]]
}
case "${1:-status}" in
  start)
    if is_running; then echo "Already running (PID $pid)."; exit 0; fi
    nohup bash "$ROOT/scripts/auto-sync-data-repo.sh" run >> "$STATE/log" 2>&1 < /dev/null &
    for _ in {1..20}; do
      if is_running; then echo "Started (PID $pid); interval ${interval}s; log: $STATE/log"; exit 0; fi
      sleep 0.1
    done
    echo "Start failed; inspect $STATE/log"; exit 1
    ;;
  status)
    if is_running; then
      echo "Running (PID $pid)."
      if [[ -f "$STATE/last-result" ]]; then cat "$STATE/last-result"; else echo 'Waiting for first scheduled sync.'; fi
    else echo 'Stopped.'; exit 1; fi
    ;;
  stop)
    if is_running; then kill -TERM "$pid"; echo 'Stop requested; any active sync will finish first.'; else echo 'Already stopped.'; fi
    ;;
  run)
    command -v flock >/dev/null
    cd "${GOUTOU_DATA_DIR:-$ROOT/data}"
    exec 8>"$(git rev-parse --git-path goutou-scheduler.lock)"
    flock -n 8 || exit 0
    echo "$$" > "$STATE/pid"
    stopping=0
    sleeper=''
    request_stop() { stopping=1; if [[ -n "$sleeper" ]]; then kill "$sleeper" 2>/dev/null || true; fi; }
    trap request_stop TERM INT
    trap 'rm -f "$STATE/pid"' EXIT
    while [[ "$stopping" == 0 ]]; do
      # First sync is delayed too: starting a conversation never triggers a push.
      sleep "$interval" 8>&- &
      sleeper=$!
      wait "$sleeper" || true
      sleeper=''
      [[ "$stopping" == 0 ]] || break
      rc=0
      bash "$ROOT/scripts/sync-data-repo.sh" 8>&- || rc=$?
      printf '%s exit=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$rc" > "$STATE/last-result"
      # Bound logs; retain one previous chunk for diagnosis.
      if [[ -f "$STATE/log" ]] && (( $(wc -c < "$STATE/log") > 1048576 )); then
        tail -c 524288 "$STATE/log" > "$STATE/log.previous"
        : > "$STATE/log"
      fi
    done
    ;;
  *) echo "Usage: $0 start|stop|status|run"; exit 1 ;;
esac
