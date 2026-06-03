#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
source "$PLUGIN_ROOT/scripts/lib/common.sh"

with_hooks=0
target_arg=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --with-hooks) with_hooks=1; shift ;;
    *) target_arg="$1"; shift ;;
  esac
done
TARGET_DIR="${target_arg:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

CENTAUR_DIR="$TARGET_DIR/.centaur"
CONTRACT="$CENTAUR_DIR/contract.md"
RUNTIME_README="$CENTAUR_DIR/README.md"
GITIGNORE="$TARGET_DIR/.gitignore"
POLICY="$TARGET_DIR/CLAUDE.md"

mkdir -p "$CENTAUR_DIR"

created_contract=0
created_readme=0
created_policy=0
updated_gitignore=0

if [ ! -f "$CONTRACT" ]; then
  cp "$PLUGIN_ROOT/templates/contract.md" "$CONTRACT"
  created_contract=1
fi

if [ ! -f "$RUNTIME_README" ]; then
  cp "$PLUGIN_ROOT/templates/runtime-readme.md" "$RUNTIME_README"
  created_readme=1
fi

if [ ! -f "$POLICY" ]; then
  cp "$PLUGIN_ROOT/templates/claude.md" "$POLICY"
  created_policy=1
fi

touch "$GITIGNORE"
for pattern in ".centaur/metrics.jsonl" ".centaur/session.json"; do
  if ! grep -qxF "$pattern" "$GITIGNORE"; then
    printf '%s\n' "$pattern" >> "$GITIGNORE"
    updated_gitignore=1
  fi
done

touch "$CENTAUR_DIR/metrics.jsonl"

charter="absent"
if [ -d "$TARGET_DIR/.claude/knowledge/charter" ] || [ -d "$TARGET_DIR/.claude" ]; then
  charter="detected"
fi

se="absent"
if [ -d "$TARGET_DIR/.se" ]; then
  se="detected"
fi

printf 'CENTAUR INIT: complete\n'
printf 'contract: %s (%s)\n' "$CONTRACT" "$([ "$created_contract" -eq 1 ] && printf created || printf preserved)"
printf 'runtime_readme: %s (%s)\n' "$RUNTIME_README" "$([ "$created_readme" -eq 1 ] && printf created || printf preserved)"
printf 'policy: %s (%s)\n' "$POLICY" "$([ "$created_policy" -eq 1 ] && printf created || printf preserved)"
printf 'gitignore: %s\n' "$([ "$updated_gitignore" -eq 1 ] && printf updated || printf unchanged)"
printf 'integration.claude_charter: %s\n' "$charter"
printf 'integration.se: %s\n' "$se"
hooks_state="absent"
if [ "$with_hooks" -eq 1 ]; then
  if bash "$PLUGIN_ROOT/scripts/centaur-install-hooks.sh" "$TARGET_DIR" >/dev/null 2>&1; then
    hooks_state="installed"
  else
    hooks_state="failed"
  fi
fi
printf 'hooks: %s\n' "$hooks_state"

printf 'next: run centaur-contract to fill the Active Contract section\n'

centaur_emit_metric "$TARGET_DIR" "init" \
  "contract_created=$created_contract" \
  "policy_created=$created_policy" \
  "charter=$charter" \
  "se=$se" \
  "hooks=$hooks_state"

exit 0
