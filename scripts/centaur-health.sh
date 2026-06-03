#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
source "$PLUGIN_ROOT/scripts/lib/common.sh"

TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
cd "$TARGET_DIR"

has_contract=0
valid_contract=0
has_policy_file=0
has_charter_policy=0
has_centaur_policy=0
has_context=0
has_verification_command=0
has_guardrails=0
has_git=0
git_clean=0
has_se=0

missing=()
signals=()

file_has_centaur_policy() {
  local file="$1"
  grep -qiE 'Centaur Principles|human owns|Generated code|generated code|verification command|narrowest meaningful verification|risky changes|explicit confirmation' "$file" 2>/dev/null
}

if [ -f ".centaur/contract.md" ]; then
  has_contract=1
  required=(
    "# Centaur Contract"
    "## Repository Defaults"
    "### Human Owns"
    "### AI May Do"
    "### Requires Explicit Confirmation"
    "### Verification Required"
    "## Active Contract"
  )
  valid_contract=1
  for heading in "${required[@]}"; do
    if ! grep -qF "$heading" .centaur/contract.md; then
      valid_contract=0
      break
    fi
  done
fi

if [ -f "CLAUDE.md" ]; then
  has_policy_file=1
  if file_has_centaur_policy "CLAUDE.md"; then
    has_centaur_policy=1
  fi
fi

if [ -d ".claude/knowledge/charter" ]; then
  has_charter_policy=1
  has_policy_file=1
fi

if [ -d ".claude/knowledge/context" ] || [ -d "docs" ] || [ -f "README.md" ]; then
  has_context=1
fi

if centaur_has_test_runner "."; then
  has_verification_command=1
fi

if [ -f ".claude/hooks/hooks.json" ] || [ -f "scripts/guardrails.sh" ]; then
  has_guardrails=1
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  has_git=1
  if [ -z "$(git status --short)" ]; then
    git_clean=1
  fi
fi

if [ -d ".se" ]; then
  has_se=1
fi

[ "$has_contract" -eq 1 ] && signals+=("contract: present") || missing+=("Run centaur-init to create .centaur/contract.md")
[ "$valid_contract" -eq 1 ] && signals+=("contract_sections: valid") || missing+=("Restore required sections in .centaur/contract.md")
if [ "$has_policy_file" -eq 1 ]; then
  signals+=("policy_file: present")
else
  signals+=("policy_file: absent")
  missing+=("Run centaur-init or add CLAUDE.md")
fi
if [ "$has_centaur_policy" -eq 1 ]; then
  signals+=("centaur_policy: detected")
else
  signals+=("centaur_policy: missing")
  missing+=("Add Centaur policy language to CLAUDE.md")
fi
[ "$has_charter_policy" -eq 1 ] && signals+=("charter_policy: detected") || signals+=("charter_policy: absent")
[ "$has_context" -eq 1 ] && signals+=("context: present") || missing+=("Add README.md or docs/architecture.md")
if [ "$has_verification_command" -eq 1 ]; then
  signals+=("verification_command: detected")
else
  signals+=("verification_command: missing")
  missing+=("Add a package.json test script, Makefile test target, or native test runner")
fi
if [ "$has_guardrails" -eq 1 ]; then
  signals+=("guardrails: detected")
else
  signals+=("guardrails: missing")
  missing+=("Add guardrails for destructive commands")
fi
[ "$has_git" -eq 1 ] && signals+=("git: repository") || missing+=("Initialize git before AI-assisted changes")
[ "$git_clean" -eq 1 ] && signals+=("git_clean: yes") || signals+=("git_clean: no")
[ "$has_se" -eq 1 ] && signals+=("se: detected") || signals+=("se: absent")

score=$((has_contract + valid_contract + has_policy_file + has_centaur_policy + has_context + has_verification_command + has_guardrails + has_git))
status="RISKY"
if [ "$score" -ge 7 ] && [ "$git_clean" -eq 1 ]; then
  status="READY"
elif [ "$score" -ge 3 ]; then
  status="PARTIAL"
fi

printf 'CENTAUR HEALTH: %s\n' "$status"
printf '\nSignals:\n'
for signal in "${signals[@]}"; do
  printf -- '- %s\n' "$signal"
done

printf '\nTop fixes:\n'
if [ "${#missing[@]}" -eq 0 ]; then
  printf -- '- No structural fixes required; keep verifying AI-generated changes.\n'
else
  count=0
  for item in "${missing[@]}"; do
    printf -- '- %s\n' "$item"
    count=$((count + 1))
    [ "$count" -ge 3 ] && break
  done
fi

printf '\nSuggested next command:\n'
if [ "$has_contract" -eq 0 ] || [ "$has_policy_file" -eq 0 ]; then
  printf -- '- centaur-init\n'
elif [ "$has_centaur_policy" -eq 0 ]; then
  printf -- '- add Centaur policy language to CLAUDE.md, then rerun centaur-health\n'
elif [ "$has_context" -eq 0 ]; then
  printf -- '- add README.md or docs/architecture.md, then rerun centaur-health\n'
elif [ "$has_verification_command" -eq 0 ]; then
  printf -- '- add a test command, then rerun centaur-health\n'
elif [ "$has_guardrails" -eq 0 ]; then
  printf -- '- add destructive-command guardrails, then rerun centaur-health\n'
else
  printf -- '- centaur-check before accepting the next AI-generated diff\n'
fi

centaur_emit_metric "$TARGET_DIR" "health" \
  "status=$status" \
  "score=$score" \
  "git_clean=$git_clean"

exit 0
