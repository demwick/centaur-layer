#!/usr/bin/env bash
# Centaur Layer pre-commit hook.
# Runs `centaur-check --staged` and blocks the commit when risk is high.
# Override threshold with CENTAUR_FAIL_ON=low|medium|high|none.
# Bypass once with `git commit --no-verify`.

set -uo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

centaur_script=""
if [ -n "${CENTAUR_PLUGIN_ROOT:-}" ] && [ -f "$CENTAUR_PLUGIN_ROOT/scripts/centaur-check.sh" ]; then
  centaur_script="$CENTAUR_PLUGIN_ROOT/scripts/centaur-check.sh"
elif [ -f "$HOME/.centaur/plugin/scripts/centaur-check.sh" ]; then
  centaur_script="$HOME/.centaur/plugin/scripts/centaur-check.sh"
elif command -v centaur-check >/dev/null 2>&1; then
  centaur_script="$(command -v centaur-check)"
fi

if [ -z "$centaur_script" ]; then
  printf 'centaur pre-commit: centaur-check.sh not found; skipping (set CENTAUR_PLUGIN_ROOT to fix)\n' >&2
  exit 0
fi

bash "$centaur_script" --staged "$repo_root"
rc=$?

if [ "$rc" -ne 0 ]; then
  printf '\ncentaur pre-commit: blocking commit (risk threshold reached).\n' >&2
  printf 'Override once: git commit --no-verify\n' >&2
  printf 'Change threshold: CENTAUR_FAIL_ON=none|low|medium|high git commit ...\n' >&2
fi

exit "$rc"
