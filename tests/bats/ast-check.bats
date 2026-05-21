load helpers/setup.bash

@test "ast-check marks clean python file as clean" {
  tmp="$(mktemp -d)"
  cat > "$tmp/clean.py" <<'PY'
# This comment mentions auth and permission but the code is unrelated.
text = "this string mentions secret"
def hello():
    return "world"
PY
  run centaur_run_script centaur-ast-check.sh "$tmp/clean.py"
  centaur_assert_contains "$output" "clean"
}

@test "ast-check marks sensitive python function as sensitive" {
  tmp="$(mktemp -d)"
  cat > "$tmp/auth.py" <<'PY'
def authenticate_user(token):
    return True
PY
  run centaur_run_script centaur-ast-check.sh "$tmp/auth.py"
  centaur_assert_contains "$output" "sensitive"
}

@test "ast-check strips comments and strings for js" {
  tmp="$(mktemp -d)"
  cat > "$tmp/clean.js" <<'JS'
// permission word in a comment
const note = "auth string literal";
function hello() { return 1; }
JS
  run centaur_run_script centaur-ast-check.sh "$tmp/clean.js"
  centaur_assert_contains "$output" "clean"
}

@test "ast-check flags real js identifier" {
  tmp="$(mktemp -d)"
  cat > "$tmp/sensitive.js" <<'JS'
function getAuthToken() { return process.env.SECRET; }
JS
  run centaur_run_script centaur-ast-check.sh "$tmp/sensitive.js"
  centaur_assert_contains "$output" "sensitive"
}

@test "centaur-check --ast downgrades false-positive filename match" {
  repo="$(centaur_mktemp_repo)"
  mkdir -p "$repo/src"
  cat > "$repo/src/auth_notes.py" <<'PY'
def hello():
    return "world"
PY
  centaur_seed_commit "$repo" src/auth_notes.py
  printf '\nx = 1\n' >> "$repo/src/auth_notes.py"

  run centaur_run_script centaur-check.sh "$repo"
  centaur_assert_contains "$output" "CENTAUR CHECK: high"

  run centaur_run_script centaur-check.sh --ast "$repo"
  centaur_assert_contains "$output" "CENTAUR CHECK: medium"
}

@test "centaur-check --ast keeps high when content is genuinely sensitive" {
  repo="$(centaur_mktemp_repo)"
  mkdir -p "$repo/src"
  cat > "$repo/src/helper.py" <<'PY'
def hello():
    return "world"
PY
  centaur_seed_commit "$repo" src/helper.py
  cat > "$repo/src/auth_module.py" <<'PY'
def authenticate(token):
    return True
PY
  run centaur_run_script centaur-check.sh --ast "$repo"
  [ "$status" -eq 1 ]
  centaur_assert_contains "$output" "CENTAUR CHECK: high"
  centaur_assert_contains "$output" "AST-confirmed"
}
