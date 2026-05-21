#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
cd "$TARGET_DIR"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'CENTAUR CHECK: unavailable\n'
  printf 'reason: not a git repository\n'
  exit 0
fi

files="$( { git diff --name-only; git diff --cached --name-only; } | sort -u )"

if [ -z "$files" ]; then
  printf 'CENTAUR CHECK: none\n'
  printf 'observed_change: no working tree or staged diff\n'
  printf 'recommendation: make a change, then run centaur-check again\n'
  exit 0
fi

risk="low"
reasons=()

while IFS= read -r file; do
  [ -n "$file" ] || continue
  case "$file" in
    *.md|docs/*|README.md|LICENSE)
      ;;
    package.json|package-lock.json|pnpm-lock.yaml|yarn.lock|bun.lock*|Cargo.toml|Cargo.lock|go.mod|go.sum|requirements*.txt|pyproject.toml)
      risk="high"
      reasons+=("dependency or build metadata changed: $file")
      ;;
    *auth*|*Auth*|*session*|*Session*|*permission*|*Permission*|*billing*|*Billing*|*secret*|*.env*|*schema*|*migration*)
      risk="high"
      reasons+=("sensitive domain changed: $file")
      ;;
    *test*|tests/*|__tests__/*)
      [ "$risk" = "low" ] && risk="low"
      ;;
    *)
      [ "$risk" = "low" ] && risk="medium"
      ;;
  esac
done <<< "$files"

file_count="$(printf '%s\n' "$files" | sed '/^$/d' | wc -l | tr -d ' ')"
if [ "$file_count" -gt 3 ] && [ "$risk" != "high" ]; then
  risk="medium"
  reasons+=("diff touches more than three files")
fi

if [ -f ".centaur/contract.md" ]; then
  if grep -qiE 'dependency.*confirmation|dependency.*require' .centaur/contract.md; then
    if printf '%s\n' "$files" | grep -qE '(^|/)(package.json|package-lock.json|pnpm-lock.yaml|yarn.lock|Cargo.toml|Cargo.lock|go.mod|go.sum|requirements.*\.txt|pyproject.toml)$'; then
      risk="high"
      reasons+=("contract requires confirmation for dependency changes")
    fi
  fi
  if grep -qiE 'auth|permission|secret|billing|schema|migration' .centaur/contract.md; then
    if printf '%s\n' "$files" | grep -qiE 'auth|permission|secret|billing|schema|migration'; then
      risk="high"
      reasons+=("contract marks this domain as confirmation-sensitive")
    fi
  fi
fi

printf 'CENTAUR CHECK: %s\n' "$risk"
printf '\nObserved change:\n'
printf '%s\n' "$files" | sed '/^$/d; s/^/- /'

printf '\nRisk reasons:\n'
if [ "${#reasons[@]}" -eq 0 ]; then
  printf -- '- no high-risk patterns detected\n'
else
  for reason in "${reasons[@]}"; do
    printf -- '- %s\n' "$reason"
  done
fi

printf '\nQuestions:\n'
case "$risk" in
  high)
    printf -- '- What behavior is intended to change, and what must remain unchanged?\n'
    printf -- '- Which command proves this change is safe enough to accept?\n'
    printf -- '- Which edge case would be most expensive to miss here?\n'
    ;;
  medium)
    printf -- '- What user-visible behavior changed in this diff?\n'
    printf -- '- Which test should fail if the implementation is wrong?\n'
    ;;
  low)
    printf -- '- Is this change limited to the intended docs, tests, or local cleanup scope?\n'
    printf -- '- Is there any adjacent behavior that should still be verified?\n'
    ;;
esac

printf '\nVerification:\n'
if [ "$risk" = "high" ]; then
  printf -- '- Required before acceptance: state intended behavior and run the relevant verification command.\n'
else
  printf -- '- Recommended: run the narrowest relevant test, lint, or review command.\n'
fi

printf '\nRecommendation:\n'
if [ "$risk" = "high" ]; then
  printf -- '- Revise or verify before accepting this AI-generated change.\n'
else
  printf -- '- Accept only after the questions above have clear answers.\n'
fi

exit 0
