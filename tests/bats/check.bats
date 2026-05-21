load helpers/setup.bash

@test "centaur-check reports unavailable outside git" {
  repo="$(mktemp -d)"
  out="$(centaur_run_script centaur-check.sh "$repo")"
  centaur_assert_contains "$out" "CENTAUR CHECK: unavailable"
}

@test "centaur-check reports none on clean tree" {
  repo="$(centaur_mktemp_repo)"
  out="$(centaur_run_script centaur-check.sh "$repo")"
  centaur_assert_contains "$out" "CENTAUR CHECK: none"
}

@test "centaur-check detects low risk for docs change" {
  repo="$(centaur_mktemp_repo)"
  printf '# Demo\n' > "$repo/README.md"
  centaur_seed_commit "$repo" README.md
  printf '\nMore docs.\n' >> "$repo/README.md"
  out="$(centaur_run_script centaur-check.sh "$repo")"
  centaur_assert_contains "$out" "CENTAUR CHECK: low"
  centaur_assert_contains "$out" "docs_files_changed: yes"
}

@test "centaur-check detects medium risk for product change" {
  repo="$(centaur_mktemp_repo)"
  mkdir -p "$repo/src"
  printf 'export function ok() { return true; }\n' > "$repo/src/app.js"
  centaur_seed_commit "$repo" src/app.js
  printf 'export function ok() { return false; }\n' > "$repo/src/app.js"
  out="$(centaur_run_script centaur-check.sh "$repo")"
  centaur_assert_contains "$out" "CENTAUR CHECK: medium"
  centaur_assert_contains "$out" "product_files_changed: 1"
}

@test "centaur-check detects high risk for dependency change without lockfile" {
  repo="$(centaur_mktemp_repo)"
  printf '{"scripts":{"test":"echo ok"}}\n' > "$repo/package.json"
  centaur_seed_commit "$repo" package.json
  printf '{"scripts":{"test":"echo ok"},"dependencies":{"left-pad":"1.3.0"}}\n' > "$repo/package.json"
  run centaur_run_script centaur-check.sh "$repo"
  [ "$status" -eq 1 ]
  centaur_assert_contains "$output" "CENTAUR CHECK: high"
  centaur_assert_contains "$output" "dependency metadata changed without lockfile evidence"
}

@test "centaur-check detects mixed setup and product changes" {
  repo="$(centaur_mktemp_repo)"
  printf '# Demo\n' > "$repo/README.md"
  centaur_seed_commit "$repo" README.md
  printf '\nMore.\n' >> "$repo/README.md"
  centaur_run_script centaur-init.sh "$repo" >/dev/null
  out="$(centaur_run_script centaur-check.sh "$repo")"
  centaur_assert_contains "$out" "setup files mixed with product changes"
}

@test "centaur-check flags missing test runner with dep change" {
  repo="$(centaur_mktemp_repo)"
  printf '{"name":"demo"}\n' > "$repo/package.json"
  centaur_seed_commit "$repo" package.json
  printf '{"name":"demo","dependencies":{"left-pad":"1.3.0"}}\n' > "$repo/package.json"
  run centaur_run_script centaur-check.sh "$repo"
  [ "$status" -eq 1 ]
  centaur_assert_contains "$output" "dependency change without test command evidence"
}

@test "centaur-check exit code respects CENTAUR_FAIL_ON=none" {
  repo="$(centaur_mktemp_repo)"
  printf '{"scripts":{"test":"echo ok"}}\n' > "$repo/package.json"
  centaur_seed_commit "$repo" package.json
  printf '{"scripts":{"test":"echo ok"},"dependencies":{"left-pad":"1.3.0"}}\n' > "$repo/package.json"
  run env CENTAUR_FAIL_ON=none bash "$CENTAUR_ROOT/scripts/centaur-check.sh" "$repo"
  [ "$status" -eq 0 ]
}

@test "centaur-check exit code respects CENTAUR_FAIL_ON=medium" {
  repo="$(centaur_mktemp_repo)"
  mkdir -p "$repo/src"
  printf 'export function ok() { return true; }\n' > "$repo/src/app.js"
  centaur_seed_commit "$repo" src/app.js
  printf 'export function ok() { return false; }\n' > "$repo/src/app.js"
  run env CENTAUR_FAIL_ON=medium bash "$CENTAUR_ROOT/scripts/centaur-check.sh" "$repo"
  [ "$status" -eq 1 ]
}
