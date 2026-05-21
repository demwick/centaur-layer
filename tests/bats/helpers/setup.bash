#!/usr/bin/env bash
# Shared helpers for Centaur Layer bats tests.

CENTAUR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
export CENTAUR_ROOT

centaur_mktemp_repo() {
  local dir
  dir="$(mktemp -d)"
  git -C "$dir" init -q
  git -C "$dir" config user.email "centaur@example.com"
  git -C "$dir" config user.name "Centaur"
  printf '%s\n' "$dir"
}

centaur_seed_commit() {
  local repo="$1" file="$2"
  git -C "$repo" add "$file"
  git -C "$repo" commit -q -m "seed: $file"
}

centaur_assert_contains() {
  local haystack="$1"
  local needle="$2"
  if ! grep -qF "$needle" <<< "$haystack"; then
    printf 'expected output to contain: %s\n' "$needle" >&2
    printf 'actual output:\n%s\n' "$haystack" >&2
    return 1
  fi
}

centaur_assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  if grep -qF "$needle" <<< "$haystack"; then
    printf 'did not expect output to contain: %s\n' "$needle" >&2
    return 1
  fi
}

centaur_run_script() {
  local script="$1"
  shift
  bash "$CENTAUR_ROOT/scripts/$script" "$@"
}
