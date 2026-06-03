#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

pass=0

ok() {
  pass=$((pass + 1))
  printf 'ok %s\n' "$1"
}

fail() {
  printf 'FAIL %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local name="$1"
  local haystack="$2"
  local needle="$3"
  if grep -qF "$needle" <<< "$haystack"; then
    ok "$name"
  else
    fail "$name missing '$needle'"
  fi
}

tmpdirs=()
cleanup() {
  [ "${#tmpdirs[@]}" -eq 0 ] && return 0
  for dir in "${tmpdirs[@]}"; do
    [ -n "$dir" ] || continue
    rm -rf "$dir"
  done
}
trap cleanup EXIT

mktemp_repo() {
  local dir
  dir="$(mktemp -d)"
  tmpdirs+=("$dir")
  git -C "$dir" init -q
  printf '%s\n' "$dir"
}

python3 -m json.tool .codex-plugin/plugin.json >/dev/null
ok "codex plugin.json parses"

python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path(".codex-plugin/plugin.json").read_text())
required = ["name", "version", "description", "license", "skills", "interface"]
missing = [key for key in required if key not in data]
if missing:
    raise SystemExit(f"missing manifest keys: {', '.join(missing)}")
if data["name"] != "centaur-layer":
    raise SystemExit("manifest name must be centaur-layer")
if data["skills"] != "./skills/":
    raise SystemExit("manifest skills must point to ./skills/")
interface = data["interface"]
for key in ["displayName", "shortDescription", "category", "capabilities"]:
    if key not in interface:
        raise SystemExit(f"missing interface.{key}")
PY
ok "codex plugin.json has required fields"

python3 -m json.tool .claude-plugin/plugin.json >/dev/null
ok "claude-code plugin.json parses"

python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path(".claude-plugin/plugin.json").read_text())
required = ["name", "version", "description"]
missing = [key for key in required if key not in data]
if missing:
    raise SystemExit(f"missing manifest keys: {', '.join(missing)}")
if data["name"] != "centaur-layer":
    raise SystemExit("manifest name must be centaur-layer")
PY
ok "claude-code plugin.json has required fields"

python3 -m json.tool .agents/plugins/marketplace.json >/dev/null
ok "codex marketplace.json parses"

python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path(".agents/plugins/marketplace.json").read_text())
for key in ["name", "plugins"]:
    if key not in data:
        raise SystemExit(f"codex marketplace.json missing key: {key}")
plugins = data["plugins"]
if not isinstance(plugins, list) or not plugins:
    raise SystemExit("codex marketplace.json must list at least one plugin")
entry = plugins[0]
for key in ["name", "source"]:
    if key not in entry:
        raise SystemExit(f"codex plugin entry missing key: {key}")
if entry["name"] != "centaur-layer":
    raise SystemExit("codex plugin entry name must be centaur-layer")
src = entry["source"]
if not isinstance(src, dict) or src.get("source") != "local" or "path" not in src:
    raise SystemExit("codex plugin source must be {source: local, path: ...}")
PY
ok "codex marketplace.json has required fields"

python3 -m json.tool .claude-plugin/marketplace.json >/dev/null
ok "claude-code marketplace.json parses"

python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path(".claude-plugin/marketplace.json").read_text())
for key in ["name", "owner", "plugins"]:
    if key not in data:
        raise SystemExit(f"marketplace.json missing key: {key}")
plugins = data["plugins"]
if not isinstance(plugins, list) or not plugins:
    raise SystemExit("marketplace.json must list at least one plugin")
entry = plugins[0]
for key in ["name", "source"]:
    if key not in entry:
        raise SystemExit(f"plugin entry missing key: {key}")
if entry["name"] != "centaur-layer":
    raise SystemExit("plugin entry name must be centaur-layer")
PY
ok "claude-code marketplace.json has required fields"

[ -f .claude-plugin/plugin.json ] || fail "missing .claude-plugin/plugin.json"
[ -d skills ] || fail "missing skills/ at repo root (required for claude-code plugin layout)"
ok "claude-code plugin layout present"

skill_count=0
for skill in skills/*/SKILL.md; do
  [ -f "$skill" ] || fail "no skill files found"
  head -1 "$skill" | grep -q '^---$' || fail "$skill missing opening frontmatter"
  grep -q '^name: ' "$skill" || fail "$skill missing name"
  grep -q '^description: ' "$skill" || fail "$skill missing description"
  grep -q '^---$' "$skill" || fail "$skill missing frontmatter delimiter"
  skill_count=$((skill_count + 1))
done
[ "$skill_count" -ge 5 ] || fail "expected at least 5 skills"
ok "skill frontmatter present"

for heading in \
  "# Centaur Contract" \
  "## Repository Defaults" \
  "### Human Owns" \
  "### AI May Do" \
  "### Requires Explicit Confirmation" \
  "### Verification Required" \
  "## Active Contract"; do
  grep -qF "$heading" templates/contract.md || fail "template missing $heading"
done
ok "contract template has required sections"

grep -qF "## Commit These" templates/runtime-readme.md \
  || fail "runtime README template missing committed-files section"
grep -qF "## Do Not Commit These" templates/runtime-readme.md \
  || fail "runtime README template missing ignored-files section"
ok "runtime README template has required sections"

grep -qF "## Centaur Principles" templates/claude.md \
  || fail "CLAUDE.md template missing Centaur Principles"
grep -qF "## Required Behavior" templates/claude.md \
  || fail "CLAUDE.md template missing Required Behavior"
ok "CLAUDE.md template has required sections"

grep -qF "none requires installing the others" README.md \
  || fail "README must state standalone positioning (Detect & Defer independence)"
grep -qiE "opt-in synthetic|synthetic drills only|synthetic-only|defect drills should be opt-in" README.md \
  || fail "README must keep defect drills opt-in"
ok "README product guardrails present"

for script in scripts/*.sh; do
  bash -n "$script"
done
ok "shell scripts parse"

tmp="$(mktemp_repo)"
init_out="$(bash scripts/centaur-init.sh "$tmp")"
[ -f "$tmp/.centaur/contract.md" ] || fail "centaur-init did not create contract"
[ -f "$tmp/.centaur/README.md" ] || fail "centaur-init did not create runtime README"
[ -f "$tmp/CLAUDE.md" ] || fail "centaur-init did not create CLAUDE.md"
grep -qxF ".centaur/metrics.jsonl" "$tmp/.gitignore" || fail "centaur-init did not ignore metrics"
grep -qxF ".centaur/session.json" "$tmp/.gitignore" || fail "centaur-init did not ignore session"
assert_contains "centaur-init reports completion" "$init_out" "CENTAUR INIT: complete"
assert_contains "centaur-init reports policy creation" "$init_out" "policy:"
assert_contains "centaur-init does not report generated CLAUDE as charter" "$init_out" "integration.claude_charter: absent"

printf '\nCUSTOM MARKER\n' >> "$tmp/.centaur/contract.md"
bash scripts/centaur-init.sh "$tmp" >/dev/null
grep -q "CUSTOM MARKER" "$tmp/.centaur/contract.md" || fail "centaur-init overwrote existing contract"
ok "centaur-init preserves existing contract"

policy_tmp="$(mktemp_repo)"
printf 'CUSTOM POLICY\n' > "$policy_tmp/CLAUDE.md"
bash scripts/centaur-init.sh "$policy_tmp" >/dev/null
grep -q "CUSTOM POLICY" "$policy_tmp/CLAUDE.md" || fail "centaur-init overwrote existing CLAUDE.md"
ok "centaur-init preserves existing CLAUDE.md"

health_out="$(bash scripts/centaur-health.sh "$tmp")"
assert_contains "centaur-health reports status" "$health_out" "CENTAUR HEALTH:"
assert_contains "centaur-health detects policy file" "$health_out" "policy_file: present"
assert_contains "centaur-health detects Centaur policy language" "$health_out" "centaur_policy: detected"
assert_contains "centaur-health suggests next command" "$health_out" "Suggested next command:"

risky="$(mktemp_repo)"
risky_out="$(bash scripts/centaur-health.sh "$risky")"
assert_contains "centaur-health detects risky repo" "$risky_out" "CENTAUR HEALTH: RISKY"

plain_policy="$(mktemp_repo)"
printf 'CUSTOM POLICY\n' > "$plain_policy/CLAUDE.md"
plain_policy_out="$(bash scripts/centaur-health.sh "$plain_policy")"
assert_contains "centaur-health detects plain policy file" "$plain_policy_out" "policy_file: present"
assert_contains "centaur-health flags missing Centaur policy language" "$plain_policy_out" "centaur_policy: missing"

low="$(mktemp_repo)"
printf '# Demo\n' > "$low/README.md"
git -C "$low" add README.md
git -C "$low" -c user.name=Centaur -c user.email=centaur@example.com commit -q -m "docs: seed readme"
printf '\nMore docs.\n' >> "$low/README.md"
low_out="$(bash scripts/centaur-check.sh "$low")"
assert_contains "centaur-check detects low risk" "$low_out" "CENTAUR CHECK: low"
assert_contains "centaur-check reports diff signals" "$low_out" "Diff signals:"
assert_contains "centaur-check detects docs signal" "$low_out" "docs_files_changed: yes"

medium="$(mktemp_repo)"
mkdir -p "$medium/src"
printf 'export function ok() { return true; }\n' > "$medium/src/app.js"
git -C "$medium" add src/app.js
git -C "$medium" -c user.name=Centaur -c user.email=centaur@example.com commit -q -m "feat: seed app"
printf 'export function ok() { return false; }\n' > "$medium/src/app.js"
medium_out="$(bash scripts/centaur-check.sh "$medium")"
assert_contains "centaur-check detects medium risk" "$medium_out" "CENTAUR CHECK: medium"
assert_contains "centaur-check detects product signal" "$medium_out" "product_files_changed: 1"

high="$(mktemp_repo)"
printf '{"scripts":{"test":"echo ok"}}\n' > "$high/package.json"
git -C "$high" add package.json
git -C "$high" -c user.name=Centaur -c user.email=centaur@example.com commit -q -m "chore: seed package"
printf '{"scripts":{"test":"echo ok"},"dependencies":{"left-pad":"1.3.0"}}\n' > "$high/package.json"
set +e
high_out="$(bash scripts/centaur-check.sh "$high")"
high_rc=$?
set -e
[ "$high_rc" -eq 1 ] || fail "centaur-check should exit 1 on high risk (got $high_rc)"
ok "centaur-check exit code high"
assert_contains "centaur-check detects high risk" "$high_out" "CENTAUR CHECK: high"
assert_contains "centaur-check detects missing lockfile evidence" "$high_out" "dependency metadata changed without lockfile evidence"
assert_contains "centaur-check detects dependency signal" "$high_out" "dependency_manifest_changed: yes"
assert_contains "centaur-check detects lockfile signal" "$high_out" "lockfile_evidence: no"

no_test_dep="$(mktemp_repo)"
printf '{"name":"demo"}\n' > "$no_test_dep/package.json"
git -C "$no_test_dep" add package.json
git -C "$no_test_dep" -c user.name=Centaur -c user.email=centaur@example.com commit -q -m "chore: seed package"
printf '{"name":"demo","dependencies":{"left-pad":"1.3.0"}}\n' > "$no_test_dep/package.json"
set +e
no_test_dep_out="$(bash scripts/centaur-check.sh "$no_test_dep")"
set -e
assert_contains "centaur-check detects missing test evidence" "$no_test_dep_out" "dependency change without test command evidence"

mixed="$(mktemp_repo)"
printf '# Demo\n' > "$mixed/README.md"
git -C "$mixed" add README.md
git -C "$mixed" -c user.name=Centaur -c user.email=centaur@example.com commit -q -m "docs: seed readme"
printf '\nProduct docs change.\n' >> "$mixed/README.md"
bash scripts/centaur-init.sh "$mixed" >/dev/null
mixed_out="$(bash scripts/centaur-check.sh "$mixed")"
assert_contains "centaur-check detects mixed setup and product changes" "$mixed_out" "setup files mixed with product changes"
assert_contains "centaur-check reports untracked files" "$mixed_out" "Untracked files:"
assert_contains "centaur-check detects setup signal" "$mixed_out" "setup_files_changed:"

invalid_contract="$(mktemp_repo)"
bash scripts/centaur-init.sh "$invalid_contract" >/dev/null
printf '# Broken\n' > "$invalid_contract/.centaur/contract.md"
invalid_out="$(bash scripts/centaur-health.sh "$invalid_contract")"
assert_contains "centaur-health detects invalid contract" "$invalid_out" "Restore required sections"

integrated="$(mktemp_repo)"
mkdir -p "$integrated/.claude/knowledge/charter" "$integrated/.claude/hooks" "$integrated/.se"
printf '# Policy\n' > "$integrated/.claude/knowledge/charter/principles.md"
printf '{"hooks":{}}\n' > "$integrated/.claude/hooks/hooks.json"
bash scripts/centaur-init.sh "$integrated" >/dev/null
integration_out="$(bash scripts/centaur-health.sh "$integrated")"
integration_init_out="$(bash scripts/centaur-init.sh "$integrated")"
assert_contains "centaur-init detects real charter integration" "$integration_init_out" "integration.claude_charter: detected"
assert_contains "centaur-health detects policy file" "$integration_out" "policy_file: present"
assert_contains "centaur-health detects charter policy" "$integration_out" "charter_policy: detected"
assert_contains "centaur-health detects guardrails" "$integration_out" "guardrails: detected"
assert_contains "centaur-health detects se" "$integration_out" "se: detected"

drill_out="$(bash scripts/centaur-drill.sh boundary)"
assert_contains "centaur-drill is synthetic" "$drill_out" "mode: synthetic-only"
assert_contains "centaur-drill does not write files" "$drill_out" "writes_files: no"

if [ -d tests/bats ]; then
  bats_files=(tests/bats/*.bats)
  if [ "${#bats_files[@]}" -gt 0 ] && [ -f "${bats_files[0]}" ]; then
    bash tests/bats/bin/bats "${bats_files[@]}" >&2 || fail "bats suite failed"
    ok "bats suite passed"
  fi
fi

printf '\n%d checks passed\n' "$pass"
