load helpers/setup.bash

@test "centaur-health reports RISKY on empty repo" {
  repo="$(centaur_mktemp_repo)"
  out="$(centaur_run_script centaur-health.sh "$repo")"
  centaur_assert_contains "$out" "CENTAUR HEALTH: RISKY"
}

@test "centaur-health detects policy file after init" {
  repo="$(centaur_mktemp_repo)"
  centaur_run_script centaur-init.sh "$repo" >/dev/null
  out="$(centaur_run_script centaur-health.sh "$repo")"
  centaur_assert_contains "$out" "policy_file: present"
  centaur_assert_contains "$out" "centaur_policy: detected"
}

@test "centaur-health flags missing Centaur policy on plain CLAUDE.md" {
  repo="$(centaur_mktemp_repo)"
  printf 'CUSTOM POLICY\n' > "$repo/CLAUDE.md"
  out="$(centaur_run_script centaur-health.sh "$repo")"
  centaur_assert_contains "$out" "policy_file: present"
  centaur_assert_contains "$out" "centaur_policy: missing"
}

@test "centaur-health flags invalid contract sections" {
  repo="$(centaur_mktemp_repo)"
  centaur_run_script centaur-init.sh "$repo" >/dev/null
  printf '# Broken\n' > "$repo/.centaur/contract.md"
  out="$(centaur_run_script centaur-health.sh "$repo")"
  centaur_assert_contains "$out" "Restore required sections"
}

@test "centaur-health detects charter, guardrails, sea integrations" {
  repo="$(centaur_mktemp_repo)"
  mkdir -p "$repo/.claude/knowledge/charter" "$repo/.claude/hooks" "$repo/.sea"
  printf '# Policy\n' > "$repo/.claude/knowledge/charter/principles.md"
  printf '{"hooks":{}}\n' > "$repo/.claude/hooks/hooks.json"
  centaur_run_script centaur-init.sh "$repo" >/dev/null
  out="$(centaur_run_script centaur-health.sh "$repo")"
  centaur_assert_contains "$out" "charter_policy: detected"
  centaur_assert_contains "$out" "guardrails: detected"
  centaur_assert_contains "$out" "sea: detected"
}
