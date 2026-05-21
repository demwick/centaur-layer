load helpers/setup.bash

@test "centaur-init creates contract, runtime README, CLAUDE.md" {
  repo="$(centaur_mktemp_repo)"
  out="$(centaur_run_script centaur-init.sh "$repo")"
  [ -f "$repo/.centaur/contract.md" ]
  [ -f "$repo/.centaur/README.md" ]
  [ -f "$repo/CLAUDE.md" ]
  centaur_assert_contains "$out" "CENTAUR INIT: complete"
}

@test "centaur-init populates gitignore with runtime patterns" {
  repo="$(centaur_mktemp_repo)"
  centaur_run_script centaur-init.sh "$repo" >/dev/null
  grep -qxF ".centaur/metrics.jsonl" "$repo/.gitignore"
  grep -qxF ".centaur/session.json" "$repo/.gitignore"
}

@test "centaur-init preserves existing contract" {
  repo="$(centaur_mktemp_repo)"
  centaur_run_script centaur-init.sh "$repo" >/dev/null
  printf '\nCUSTOM MARKER\n' >> "$repo/.centaur/contract.md"
  centaur_run_script centaur-init.sh "$repo" >/dev/null
  grep -q "CUSTOM MARKER" "$repo/.centaur/contract.md"
}

@test "centaur-init preserves existing CLAUDE.md" {
  repo="$(centaur_mktemp_repo)"
  printf 'CUSTOM POLICY\n' > "$repo/CLAUDE.md"
  centaur_run_script centaur-init.sh "$repo" >/dev/null
  grep -q "CUSTOM POLICY" "$repo/CLAUDE.md"
}

@test "centaur-init reports charter absent when not detected" {
  repo="$(centaur_mktemp_repo)"
  out="$(centaur_run_script centaur-init.sh "$repo")"
  centaur_assert_contains "$out" "integration.claude_charter: absent"
}

@test "centaur-init detects charter directory" {
  repo="$(centaur_mktemp_repo)"
  mkdir -p "$repo/.claude/knowledge/charter"
  out="$(centaur_run_script centaur-init.sh "$repo")"
  centaur_assert_contains "$out" "integration.claude_charter: detected"
}
