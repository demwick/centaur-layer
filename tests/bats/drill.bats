load helpers/setup.bash

@test "centaur-drill boundary mode is synthetic-only" {
  out="$(centaur_run_script centaur-drill.sh boundary)"
  centaur_assert_contains "$out" "CENTAUR DRILL: boundary"
  centaur_assert_contains "$out" "mode: synthetic-only"
  centaur_assert_contains "$out" "writes_files: no"
}

@test "centaur-drill inverted-condition mode runs" {
  out="$(centaur_run_script centaur-drill.sh inverted-condition)"
  centaur_assert_contains "$out" "CENTAUR DRILL: inverted-condition"
}

@test "centaur-drill null-handling mode runs" {
  out="$(centaur_run_script centaur-drill.sh null-handling)"
  centaur_assert_contains "$out" "CENTAUR DRILL: null-handling"
}

@test "centaur-drill rejects unknown mode" {
  run centaur_run_script centaur-drill.sh bogus-mode
  [ "$status" -ne 0 ]
  centaur_assert_contains "$output" "CENTAUR DRILL: unavailable"
}
