#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

CENTAUR_DIR="$TARGET_DIR/.centaur"
CONTRACT="$CENTAUR_DIR/contract.md"
RUNTIME_README="$CENTAUR_DIR/README.md"
GITIGNORE="$TARGET_DIR/.gitignore"

mkdir -p "$CENTAUR_DIR"

created_contract=0
created_readme=0
updated_gitignore=0

if [ ! -f "$CONTRACT" ]; then
  cp "$PLUGIN_ROOT/templates/contract.md" "$CONTRACT"
  created_contract=1
fi

if [ ! -f "$RUNTIME_README" ]; then
  cp "$PLUGIN_ROOT/templates/runtime-readme.md" "$RUNTIME_README"
  created_readme=1
fi

touch "$GITIGNORE"
for pattern in ".centaur/metrics.jsonl" ".centaur/session.json"; do
  if ! grep -qxF "$pattern" "$GITIGNORE"; then
    printf '%s\n' "$pattern" >> "$GITIGNORE"
    updated_gitignore=1
  fi
done

charter="absent"
if [ -f "$TARGET_DIR/CLAUDE.md" ] || [ -d "$TARGET_DIR/.claude" ]; then
  charter="detected"
fi

sea="absent"
if [ -d "$TARGET_DIR/.sea" ]; then
  sea="detected"
fi

printf 'CENTAUR INIT: complete\n'
printf 'contract: %s (%s)\n' "$CONTRACT" "$([ "$created_contract" -eq 1 ] && printf created || printf preserved)"
printf 'runtime_readme: %s (%s)\n' "$RUNTIME_README" "$([ "$created_readme" -eq 1 ] && printf created || printf preserved)"
printf 'gitignore: %s\n' "$([ "$updated_gitignore" -eq 1 ] && printf updated || printf unchanged)"
printf 'integration.claude_charter: %s\n' "$charter"
printf 'integration.sea: %s\n' "$sea"
printf 'next: run centaur-contract to fill the Active Contract section\n'
