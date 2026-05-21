#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

if ! git -C "$TARGET_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'CENTAUR HOOKS: unavailable\n'
  printf 'reason: %s is not a git repository\n' "$TARGET_DIR"
  exit 1
fi

git_dir="$(git -C "$TARGET_DIR" rev-parse --git-dir)"
case "$git_dir" in
  /*) ;;
  *) git_dir="$TARGET_DIR/$git_dir" ;;
esac

hook_target="$git_dir/hooks/pre-commit"
template="$PLUGIN_ROOT/templates/pre-commit.sh"

if [ ! -f "$template" ]; then
  printf 'CENTAUR HOOKS: error\n'
  printf 'reason: template %s missing\n' "$template" >&2
  exit 1
fi

mkdir -p "$git_dir/hooks"

action="installed"
if [ -f "$hook_target" ]; then
  if grep -q "Centaur Layer pre-commit hook" "$hook_target" 2>/dev/null; then
    action="reinstalled"
  else
    backup="$hook_target.centaur-backup.$(date +%s)"
    mv "$hook_target" "$backup"
    action="installed (existing hook backed up to $backup)"
  fi
fi

cp "$template" "$hook_target"
chmod +x "$hook_target"

printf 'CENTAUR HOOKS: %s\n' "$action"
printf 'hook: %s\n' "$hook_target"
printf 'threshold: high (override with CENTAUR_FAIL_ON env var)\n'
printf 'bypass: git commit --no-verify\n'

exit 0
