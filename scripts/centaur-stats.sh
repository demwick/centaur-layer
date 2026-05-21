#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
source "$PLUGIN_ROOT/scripts/lib/common.sh"

days=7
target_dir="."
while [ "$#" -gt 0 ]; do
  case "$1" in
    --days)
      days="$2"
      shift 2
      ;;
    --days=*)
      days="${1#--days=}"
      shift
      ;;
    *)
      target_dir="$1"
      shift
      ;;
  esac
done
[[ "$days" =~ ^[0-9]+$ ]] || { printf 'CENTAUR STATS: invalid days argument\n' >&2; exit 2; }

target_dir="$(cd "$target_dir" && pwd)"
metrics="$target_dir/.centaur/metrics.jsonl"

if [ ! -f "$metrics" ]; then
  printf 'CENTAUR STATS: unavailable\n'
  printf 'reason: %s not found (run centaur-init first)\n' "$metrics"
  exit 0
fi

if date -v-1d >/dev/null 2>&1; then
  cutoff="$(date -u -v-"${days}"d +"%Y-%m-%dT00:00:00Z")"
else
  cutoff="$(date -u -d "${days} days ago" +"%Y-%m-%dT00:00:00Z")"
fi

filter_field() {
  local field="$1"
  sed -n "s/.*\"$field\":\"\\([^\"]*\\)\".*/\\1/p"
}

filter_number() {
  local field="$1"
  sed -n "s/.*\"$field\":\\([0-9]*\\).*/\\1/p"
}

in_window() {
  awk -v cutoff="$cutoff" '
    {
      ts = ""
      n = split($0, parts, "\"ts\":\"")
      if (n >= 2) {
        rest = parts[2]
        m = split(rest, kv, "\"")
        ts = kv[1]
      }
      if (ts >= cutoff) print $0
    }
  '
}

filtered="$(in_window < "$metrics")"

count_lines() {
  if [ -z "$filtered" ]; then printf '0'; return; fi
  printf '%s\n' "$filtered" | grep -c "$1" || true
}

count_event() {
  count_lines "\"event\":\"$1\""
}

count_check_risk() {
  if [ -z "$filtered" ]; then printf '0'; return; fi
  printf '%s\n' "$filtered" | grep '"event":"check"' | grep -c "\"risk\":\"$1\"" || true
}

drill_kinds() {
  [ -z "$filtered" ] && return
  printf '%s\n' "$filtered" | grep '"event":"drill"' | filter_field "kind" | sort | uniq -c | awk '{printf "  %s: %d\n", $2, $1}'
}

last_health_status() {
  [ -z "$filtered" ] && { printf 'n/a'; return; }
  local last
  last="$(printf '%s\n' "$filtered" | grep '"event":"health"' | tail -1 | filter_field "status")"
  printf '%s' "${last:-n/a}"
}

total=$([ -z "$filtered" ] && printf 0 || printf '%s\n' "$filtered" | wc -l | tr -d ' ')

printf 'CENTAUR STATS\n'
printf 'period: last %d day(s) (since %s)\n' "$days" "$cutoff"
printf 'source: %s\n' "$metrics"
printf 'events: %s\n\n' "$total"

checks=$(count_event "check")
printf 'Checks: %s\n' "$checks"
if [ "$checks" -gt 0 ]; then
  printf '  high: %s\n' "$(count_check_risk high)"
  printf '  medium: %s\n' "$(count_check_risk medium)"
  printf '  low: %s\n' "$(count_check_risk low)"
fi

drills=$(count_event "drill")
printf 'Drills: %s\n' "$drills"
[ "$drills" -gt 0 ] && drill_kinds

healths=$(count_event "health")
printf 'Health audits: %s' "$healths"
[ "$healths" -gt 0 ] && printf ' (last: %s)' "$(last_health_status)"
printf '\n'

inits=$(count_event "init")
printf 'Init events: %s\n' "$inits"

exit 0
