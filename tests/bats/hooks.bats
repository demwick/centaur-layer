load helpers/setup.bash

@test "centaur-install-hooks installs pre-commit" {
  repo="$(centaur_mktemp_repo)"
  out="$(centaur_run_script centaur-install-hooks.sh "$repo")"
  centaur_assert_contains "$out" "CENTAUR HOOKS: installed"
  [ -x "$repo/.git/hooks/pre-commit" ]
  grep -q "Centaur Layer pre-commit hook" "$repo/.git/hooks/pre-commit"
}

@test "centaur-install-hooks backs up existing non-centaur hook" {
  repo="$(centaur_mktemp_repo)"
  mkdir -p "$repo/.git/hooks"
  printf '#!/bin/sh\necho user-hook\n' > "$repo/.git/hooks/pre-commit"
  chmod +x "$repo/.git/hooks/pre-commit"
  out="$(centaur_run_script centaur-install-hooks.sh "$repo")"
  centaur_assert_contains "$out" "backed up to"
  ls "$repo/.git/hooks/" | grep -q "pre-commit.centaur-backup"
}

@test "centaur-install-hooks is idempotent for centaur hook" {
  repo="$(centaur_mktemp_repo)"
  centaur_run_script centaur-install-hooks.sh "$repo" >/dev/null
  out="$(centaur_run_script centaur-install-hooks.sh "$repo")"
  centaur_assert_contains "$out" "reinstalled"
}

@test "centaur-init --with-hooks installs pre-commit" {
  repo="$(centaur_mktemp_repo)"
  out="$(centaur_run_script centaur-init.sh --with-hooks "$repo")"
  centaur_assert_contains "$out" "hooks: installed"
  [ -x "$repo/.git/hooks/pre-commit" ]
}

@test "pre-commit hook blocks high-risk staged commit" {
  repo="$(centaur_mktemp_repo)"
  CENTAUR_PLUGIN_ROOT="$CENTAUR_ROOT" centaur_run_script centaur-init.sh --with-hooks "$repo" >/dev/null
  printf '{"scripts":{"test":"echo ok"},"dependencies":{"x":"1.0.0"}}\n' > "$repo/package.json"
  git -C "$repo" add package.json
  run env CENTAUR_PLUGIN_ROOT="$CENTAUR_ROOT" git -C "$repo" commit -m "test"
  [ "$status" -ne 0 ]
  centaur_assert_contains "$output" "blocking commit"
}

@test "pre-commit hook allows low-risk staged commit" {
  repo="$(centaur_mktemp_repo)"
  CENTAUR_PLUGIN_ROOT="$CENTAUR_ROOT" centaur_run_script centaur-init.sh --with-hooks "$repo" >/dev/null
  printf '# docs\n' > "$repo/NOTES.md"
  git -C "$repo" add NOTES.md
  run env CENTAUR_PLUGIN_ROOT="$CENTAUR_ROOT" git -C "$repo" commit -m "docs: notes"
  [ "$status" -eq 0 ]
}
