#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
source "$PLUGIN_ROOT/scripts/lib/common.sh"

mode="all"
ast_mode="${CENTAUR_AST:-0}"
target_arg=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --staged) mode="staged"; shift ;;
    --all) mode="all"; shift ;;
    --ast) ast_mode=1; shift ;;
    --no-ast) ast_mode=0; shift ;;
    *) target_arg="$1"; shift ;;
  esac
done
TARGET_DIR="${target_arg:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
cd "$TARGET_DIR"

is_setup_file() { centaur_is_setup_file "$1"; }
is_dependency_manifest() { centaur_is_dependency_manifest "$1"; }
is_lockfile() { centaur_is_lockfile "$1"; }
has_test_runner() { centaur_has_test_runner "."; }

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'CENTAUR CHECK: unavailable\n'
  printf 'reason: not a git repository\n'
  exit 0
fi

modified_files="$(git diff --name-only | sort -u)"
staged_files="$(git diff --cached --name-only | sort -u)"
untracked_files="$(git ls-files --others --exclude-standard | sort -u)"
if [ "$mode" = "staged" ]; then
  files="$(printf '%s\n' "$staged_files" | sed '/^$/d' | sort -u)"
else
  files="$( { printf '%s\n' "$modified_files"; printf '%s\n' "$staged_files"; printf '%s\n' "$untracked_files"; } | sed '/^$/d' | sort -u )"
fi

if [ -z "$files" ]; then
  printf 'CENTAUR CHECK: none\n'
  printf 'observed_change: no working tree or staged diff\n'
  printf 'recommendation: make a change, then run centaur-check again\n'
  exit 0
fi

risk="low"
reasons=()
signals=()
setup_count=0
product_count=0
dependency_manifest_changed=0
lockfile_evidence=0
test_file_changed=0
docs_file_changed=0
sensitive_domain_changed=0

while IFS= read -r file; do
  [ -n "$file" ] || continue
  if is_setup_file "$file"; then
    setup_count=$((setup_count + 1))
  else
    product_count=$((product_count + 1))
  fi
  if is_dependency_manifest "$file"; then
    dependency_manifest_changed=1
  fi
  if is_lockfile "$file"; then
    lockfile_evidence=1
  fi
  case "$file" in
    *.md|docs/*|README.md|LICENSE)
      docs_file_changed=1
      ;;
    package.json|package-lock.json|pnpm-lock.yaml|yarn.lock|bun.lock*|Cargo.toml|Cargo.lock|go.mod|go.sum|requirements*.txt|pyproject.toml)
      risk="high"
      reasons+=("dependency or build metadata changed: $file")
      ;;
    *auth*|*Auth*|*session*|*Session*|*permission*|*Permission*|*billing*|*Billing*|*secret*|*.env*|*schema*|*migration*)
      verdict="sensitive"
      if [ "$ast_mode" = "1" ] && [ -f "$file" ]; then
        verdict="$(bash "$PLUGIN_ROOT/scripts/centaur-ast-check.sh" "$file" | awk -F'\t' '{print $2}')"
        [ -z "$verdict" ] && verdict="sensitive"
      fi
      if [ "$verdict" = "sensitive" ]; then
        sensitive_domain_changed=1
        risk="high"
        if [ "$ast_mode" = "1" ]; then
          reasons+=("sensitive domain changed (AST-confirmed): $file")
        else
          reasons+=("sensitive domain changed: $file")
        fi
      else
        [ "$risk" = "low" ] && risk="medium"
      fi
      ;;
    *test*|tests/*|__tests__/*)
      test_file_changed=1
      [ "$risk" = "low" ] && risk="low"
      ;;
    *)
      [ "$risk" = "low" ] && risk="medium"
      ;;
  esac
done <<< "$files"

if [ "$setup_count" -gt 0 ] && [ "$product_count" -gt 0 ]; then
  [ "$risk" = "low" ] && risk="medium"
  reasons+=("setup files mixed with product changes")
fi

if [ "$dependency_manifest_changed" -eq 1 ] && [ "$lockfile_evidence" -eq 0 ]; then
  risk="high"
  reasons+=("dependency metadata changed without lockfile evidence")
fi

if [ "$dependency_manifest_changed" -eq 1 ] && ! has_test_runner; then
  risk="high"
  reasons+=("dependency change without test command evidence")
fi

file_count="$(printf '%s\n' "$files" | sed '/^$/d' | wc -l | tr -d ' ')"
if [ "$file_count" -gt 3 ] && [ "$risk" != "high" ]; then
  risk="medium"
  reasons+=("diff touches more than three files")
fi

signals+=("files_changed: $file_count")
[ "$setup_count" -gt 0 ] && signals+=("setup_files_changed: $setup_count") || signals+=("setup_files_changed: none")
[ "$product_count" -gt 0 ] && signals+=("product_files_changed: $product_count") || signals+=("product_files_changed: none")
[ "$docs_file_changed" -eq 1 ] && signals+=("docs_files_changed: yes") || signals+=("docs_files_changed: no")
[ "$test_file_changed" -eq 1 ] && signals+=("test_files_changed: yes") || signals+=("test_files_changed: no")
[ "$sensitive_domain_changed" -eq 1 ] && signals+=("sensitive_domain_changed: yes") || signals+=("sensitive_domain_changed: no")
[ "$dependency_manifest_changed" -eq 1 ] && signals+=("dependency_manifest_changed: yes") || signals+=("dependency_manifest_changed: no")
[ "$lockfile_evidence" -eq 1 ] && signals+=("lockfile_evidence: yes") || signals+=("lockfile_evidence: no")
if has_test_runner; then
  signals+=("test_runner: detected")
else
  signals+=("test_runner: missing")
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
printf '\nModified files:\n'
if [ -n "$modified_files" ]; then
  printf '%s\n' "$modified_files" | sed '/^$/d; s/^/- /'
else
  printf -- '- none\n'
fi

printf '\nStaged files:\n'
if [ -n "$staged_files" ]; then
  printf '%s\n' "$staged_files" | sed '/^$/d; s/^/- /'
else
  printf -- '- none\n'
fi

printf '\nUntracked files:\n'
if [ -n "$untracked_files" ]; then
  printf '%s\n' "$untracked_files" | sed '/^$/d; s/^/- /'
else
  printf -- '- none\n'
fi

printf '\nRisk reasons:\n'
if [ "${#reasons[@]}" -eq 0 ]; then
  printf -- '- no high-risk patterns detected\n'
else
  for reason in "${reasons[@]}"; do
    printf -- '- %s\n' "$reason"
  done
fi

printf '\nDiff signals:\n'
for signal in "${signals[@]}"; do
  printf -- '- %s\n' "$signal"
done

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

primary_reason="none"
if [ "${#reasons[@]}" -gt 0 ]; then
  primary_reason="${reasons[0]}"
fi
centaur_emit_metric "$TARGET_DIR" "check" \
  "risk=$risk" \
  "files=$file_count" \
  "primary_reason=$primary_reason"

fail_threshold="${CENTAUR_FAIL_ON:-high}"
case "$fail_threshold" in
  high)   [ "$risk" = "high" ] && exit 1 ;;
  medium) { [ "$risk" = "high" ] || [ "$risk" = "medium" ]; } && exit 1 ;;
  low)    [ "$risk" != "none" ] && [ "$risk" != "unavailable" ] && exit 1 ;;
  none)   ;;
esac
exit 0
