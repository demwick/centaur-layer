#!/usr/bin/env bash
set -euo pipefail

kind="${1:-boundary}"

case "$kind" in
  boundary)
    title="Boundary condition drill"
    snippet='
function canPurchase(quantity, stock) {
  return quantity < stock;
}
'
    answer="The comparison excludes the exact-stock case. If quantity equals stock, purchase should usually be allowed, so <= is likely intended."
    ;;
  inverted-condition)
    title="Inverted condition drill"
    snippet='
if (user.isAdmin) {
  return forbidden();
}
return allow();
'
    answer="The admin branch is inverted. Admin users are denied while everyone else is allowed."
    ;;
  null-handling)
    title="Null handling drill"
    snippet='
const displayName = user.profile.name.trim();
'
    answer="user, profile, or name may be nullish. The code assumes all three are present before calling trim()."
    ;;
  *)
    printf 'CENTAUR DRILL: unavailable\n'
    printf 'available: boundary, inverted-condition, null-handling\n'
    exit 1
    ;;
esac

printf 'CENTAUR DRILL: %s\n' "$kind"
printf 'mode: synthetic-only\n'
printf 'writes_files: no\n'
printf '\nPrompt:\n'
printf -- '- Review this synthetic AI suggestion. What is the hidden flaw?\n'
printf '\nSnippet:%s\n' "$snippet"
printf 'Expected finding:\n'
printf -- '- %s\n' "$answer"

exit 0
