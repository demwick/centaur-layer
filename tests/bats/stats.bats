load helpers/setup.bash

@test "centaur-stats reports unavailable without metrics file" {
  repo="$(centaur_mktemp_repo)"
  out="$(centaur_run_script centaur-stats.sh "$repo")"
  centaur_assert_contains "$out" "CENTAUR STATS: unavailable"
}

@test "centaur-stats reports zero counts on empty metrics" {
  repo="$(centaur_mktemp_repo)"
  centaur_run_script centaur-init.sh "$repo" >/dev/null
  : > "$repo/.centaur/metrics.jsonl"
  out="$(centaur_run_script centaur-stats.sh "$repo")"
  centaur_assert_contains "$out" "Checks: 0"
  centaur_assert_contains "$out" "Drills: 0"
}

@test "centaur-stats counts events emitted by other scripts" {
  repo="$(centaur_mktemp_repo)"
  centaur_run_script centaur-init.sh "$repo" >/dev/null
  printf '# x\n' > "$repo/README.md"
  centaur_run_script centaur-check.sh "$repo" >/dev/null
  CENTAUR_REPO="$repo" centaur_run_script centaur-drill.sh boundary >/dev/null
  centaur_run_script centaur-health.sh "$repo" >/dev/null
  out="$(centaur_run_script centaur-stats.sh "$repo")"
  centaur_assert_contains "$out" "Init events: 1"
  centaur_assert_contains "$out" "Checks: 1"
  centaur_assert_contains "$out" "Drills: 1"
  centaur_assert_contains "$out" "Health audits: 1"
}

@test "centaur-stats filters by --days window" {
  repo="$(centaur_mktemp_repo)"
  centaur_run_script centaur-init.sh "$repo" >/dev/null
  cat >> "$repo/.centaur/metrics.jsonl" <<'EOF'
{"ts":"2000-01-01T00:00:00Z","event":"check","risk":"high","files":1,"primary_reason":"x"}
EOF
  out="$(centaur_run_script centaur-stats.sh "$repo" --days 7)"
  centaur_assert_contains "$out" "Checks: 0"
}
