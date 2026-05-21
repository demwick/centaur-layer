#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
cd "$TARGET_DIR"

has_contract=0
valid_contract=0
has_policy=0
has_context=0
has_test=0
has_guardrails=0
has_git=0
git_clean=0
has_sea=0

missing=()
signals=()

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

if [ -f "CLAUDE.md" ] || [ -d ".claude/knowledge/charter" ]; then
  has_policy=1
fi

if [ -d ".claude/knowledge/context" ] || [ -d "docs" ] || [ -f "README.md" ]; then
  has_context=1
fi

if [ -f "package.json" ] && grep -q '"test"' package.json 2>/dev/null; then
  has_test=1
elif [ -f "pyproject.toml" ] || [ -f "pytest.ini" ]; then
  has_test=1
elif [ -f "go.mod" ] || [ -f "Cargo.toml" ]; then
  has_test=1
elif [ -f "Makefile" ] && grep -qE '^test:' Makefile 2>/dev/null; then
  has_test=1
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

if [ -d ".sea" ]; then
  has_sea=1
fi

[ "$has_contract" -eq 1 ] && signals+=("contract: present") || missing+=("Run centaur-init to create .centaur/contract.md")
[ "$valid_contract" -eq 1 ] && signals+=("contract_sections: valid") || missing+=("Restore required sections in .centaur/contract.md")
[ "$has_policy" -eq 1 ] && signals+=("policy: present") || missing+=("Add CLAUDE.md or .claude/knowledge/charter/ policy")
[ "$has_context" -eq 1 ] && signals+=("context: present") || missing+=("Add README.md, docs/, or .claude/knowledge/context/")
[ "$has_test" -eq 1 ] && signals+=("tests: detected") || missing+=("Add a test command or project test runner")
[ "$has_guardrails" -eq 1 ] && signals+=("guardrails: detected") || missing+=("Add guardrails for destructive commands")
[ "$has_git" -eq 1 ] && signals+=("git: repository") || missing+=("Initialize git before AI-assisted changes")
[ "$git_clean" -eq 1 ] && signals+=("git_clean: yes") || signals+=("git_clean: no")
[ "$has_sea" -eq 1 ] && signals+=("sea: detected") || signals+=("sea: absent")

score=$((has_contract + valid_contract + has_policy + has_context + has_test + has_guardrails + has_git))
status="RISKY"
if [ "$score" -ge 6 ] && [ "$git_clean" -eq 1 ]; then
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

exit 0
