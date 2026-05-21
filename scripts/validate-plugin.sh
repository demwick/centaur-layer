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
ok "plugin.json parses"

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
ok "plugin.json has required fields"

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

grep -q "Centaur Layer is the single product users install" README.md \
  || fail "README must state single-product positioning"
grep -qi "deliberate defect drills should be opt-in" README.md \
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
grep -qxF ".centaur/metrics.jsonl" "$tmp/.gitignore" || fail "centaur-init did not ignore metrics"
grep -qxF ".centaur/session.json" "$tmp/.gitignore" || fail "centaur-init did not ignore session"
assert_contains "centaur-init reports completion" "$init_out" "CENTAUR INIT: complete"

printf '\nCUSTOM MARKER\n' >> "$tmp/.centaur/contract.md"
bash scripts/centaur-init.sh "$tmp" >/dev/null
grep -q "CUSTOM MARKER" "$tmp/.centaur/contract.md" || fail "centaur-init overwrote existing contract"
ok "centaur-init preserves existing contract"

health_out="$(bash scripts/centaur-health.sh "$tmp")"
assert_contains "centaur-health reports status" "$health_out" "CENTAUR HEALTH:"

risky="$(mktemp_repo)"
risky_out="$(bash scripts/centaur-health.sh "$risky")"
assert_contains "centaur-health detects risky repo" "$risky_out" "CENTAUR HEALTH: RISKY"

low="$(mktemp_repo)"
printf '# Demo\n' > "$low/README.md"
git -C "$low" add README.md
git -C "$low" -c user.name=Centaur -c user.email=centaur@example.com commit -q -m "docs: seed readme"
printf '\nMore docs.\n' >> "$low/README.md"
low_out="$(bash scripts/centaur-check.sh "$low")"
assert_contains "centaur-check detects low risk" "$low_out" "CENTAUR CHECK: low"

medium="$(mktemp_repo)"
mkdir -p "$medium/src"
printf 'export function ok() { return true; }\n' > "$medium/src/app.js"
git -C "$medium" add src/app.js
git -C "$medium" -c user.name=Centaur -c user.email=centaur@example.com commit -q -m "feat: seed app"
printf 'export function ok() { return false; }\n' > "$medium/src/app.js"
medium_out="$(bash scripts/centaur-check.sh "$medium")"
assert_contains "centaur-check detects medium risk" "$medium_out" "CENTAUR CHECK: medium"

high="$(mktemp_repo)"
printf '{"scripts":{"test":"echo ok"}}\n' > "$high/package.json"
git -C "$high" add package.json
git -C "$high" -c user.name=Centaur -c user.email=centaur@example.com commit -q -m "chore: seed package"
printf '{"scripts":{"test":"echo ok"},"dependencies":{"left-pad":"1.3.0"}}\n' > "$high/package.json"
high_out="$(bash scripts/centaur-check.sh "$high")"
assert_contains "centaur-check detects high risk" "$high_out" "CENTAUR CHECK: high"

invalid_contract="$(mktemp_repo)"
bash scripts/centaur-init.sh "$invalid_contract" >/dev/null
printf '# Broken\n' > "$invalid_contract/.centaur/contract.md"
invalid_out="$(bash scripts/centaur-health.sh "$invalid_contract")"
assert_contains "centaur-health detects invalid contract" "$invalid_out" "Restore required sections"

integrated="$(mktemp_repo)"
mkdir -p "$integrated/.claude/knowledge/charter" "$integrated/.claude/hooks" "$integrated/.sea"
printf '# Policy\n' > "$integrated/.claude/knowledge/charter/principles.md"
printf '{"hooks":{}}\n' > "$integrated/.claude/hooks/hooks.json"
bash scripts/centaur-init.sh "$integrated" >/dev/null
integration_out="$(bash scripts/centaur-health.sh "$integrated")"
assert_contains "centaur-health detects charter policy" "$integration_out" "policy: present"
assert_contains "centaur-health detects guardrails" "$integration_out" "guardrails: detected"
assert_contains "centaur-health detects sea" "$integration_out" "sea: detected"

drill_out="$(bash scripts/centaur-drill.sh boundary)"
assert_contains "centaur-drill is synthetic" "$drill_out" "mode: synthetic-only"
assert_contains "centaur-drill does not write files" "$drill_out" "writes_files: no"

printf '\n%d checks passed\n' "$pass"
