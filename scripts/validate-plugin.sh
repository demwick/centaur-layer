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

printf '\n%d checks passed\n' "$pass"
