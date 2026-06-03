#!/usr/bin/env bash
# Shared helpers for Centaur Layer scripts.
# Source this file with: source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

centaur_iso_now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

centaur_json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

# emit_metric <repo_dir> <event> [key=value ...]
# Appends a JSONL line to <repo_dir>/.centaur/metrics.jsonl.
# Silent no-op if .centaur/ doesn't exist (repo not initialized).
# Disabled when CENTAUR_METRICS_DISABLED=1.
centaur_emit_metric() {
  [ "${CENTAUR_METRICS_DISABLED:-0}" = "1" ] && return 0
  local repo="$1"
  local event="$2"
  shift 2
  [ -d "$repo/.centaur" ] || return 0
  local metrics_file="$repo/.centaur/metrics.jsonl"
  local ts
  ts="$(centaur_iso_now)"
  local payload
  payload="{\"ts\":\"$ts\",\"event\":\"$(centaur_json_escape "$event")\""
  local kv key value
  for kv in "$@"; do
    key="${kv%%=*}"
    value="${kv#*=}"
    [ "$key" = "$kv" ] && continue
    if [[ "$value" =~ ^-?[0-9]+$ ]]; then
      payload+=",\"$(centaur_json_escape "$key")\":$value"
    else
      payload+=",\"$(centaur_json_escape "$key")\":\"$(centaur_json_escape "$value")\""
    fi
  done
  payload+="}"
  printf '%s\n' "$payload" >> "$metrics_file"
}

centaur_is_setup_file() {
  case "$1" in
    .centaur/*|.gitignore|CLAUDE.md)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

centaur_is_dependency_manifest() {
  case "$1" in
    package.json|Cargo.toml|go.mod|requirements*.txt|pyproject.toml)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

centaur_is_lockfile() {
  case "$1" in
    package-lock.json|pnpm-lock.yaml|yarn.lock|bun.lock*|Cargo.lock|go.sum)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

centaur_has_test_runner() {
  local dir="${1:-.}"
  if [ -f "$dir/package.json" ] && grep -q '"test"' "$dir/package.json" 2>/dev/null; then
    return 0
  elif [ -f "$dir/pyproject.toml" ] || [ -f "$dir/pytest.ini" ]; then
    return 0
  elif [ -f "$dir/go.mod" ] || [ -f "$dir/Cargo.toml" ]; then
    return 0
  elif [ -f "$dir/Makefile" ] && grep -qE '^test:' "$dir/Makefile" 2>/dev/null; then
    return 0
  elif [ -f "$dir/test.sh" ] || [ -f "$dir/run-tests.sh" ]; then
    return 0
  elif find "$dir" -maxdepth 3 -name '*.bats' -type f -print -quit 2>/dev/null | grep -q .; then
    return 0
  fi
  return 1
}
