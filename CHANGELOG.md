# Changelog

## 0.2.0 — unreleased

### Added

- **Claude Code plugin support.** Ship `.claude-plugin/plugin.json` and
  `.claude-plugin/marketplace.json` so the same repo installs as a Claude
  Code plugin (`/plugin marketplace add` + `/plugin install
  centaur-layer@centaur-layer`) without losing the existing Codex plugin
  path. SKILL files now resolve the plugin root via
  `${CLAUDE_PLUGIN_ROOT:-${CODEX_PLUGIN_ROOT:-.}}`, so the same skill
  works in either CLI. `scripts/validate-plugin.sh` validates both
  manifests.
- **Codex one-line install.** Ship `.agents/plugins/marketplace.json` so
  Codex users can install via the GitHub shorthand
  (`codex plugin marketplace add demwick/centaur-layer` +
  `codex plugin add centaur-layer@centaur-layer`) instead of having to
  clone first and pass `--marketplace`.


- `centaur-stats` skill and `scripts/centaur-stats.sh` — summarize local
  Centaur usage (checks, drills, health audits, init events) over a
  configurable window (default 7 days).
- Metrics emission across `centaur-init`, `centaur-check`, `centaur-health`,
  `centaur-drill`. Lines are appended to `.centaur/metrics.jsonl` as JSONL.
- `centaur-install-hooks` skill and `scripts/centaur-install-hooks.sh` —
  installs a local pre-commit hook (`templates/pre-commit.sh`) that runs
  `centaur-check --staged` and blocks commits at or above the configured
  risk threshold. Existing non-Centaur hooks are backed up.
- `centaur-init --with-hooks` — installs the hook as part of init.
- `centaur-check --staged` — restrict scoring to staged files (used by the
  pre-commit hook and the GitHub Action).
- `centaur-check --ast` and `scripts/centaur-ast-check.sh` — AST-aware
  sensitive-domain check. Uses Python's built-in `ast` module for `.py`
  files and a comment/string-stripping fallback for other languages.
  Downgrades false positives where the filename matches a sensitive
  keyword but the content does not.
- GitHub Action template (`templates/github-action.yml`) and self-check
  workflow (`.github/workflows/centaur-self-check.yml`).
- In-tree minimal bats-compatible runner (`tests/bats/bin/bats`) and
  regression suite under `tests/bats/`. `scripts/validate-plugin.sh`
  invokes the suite on every run.
- `scripts/lib/common.sh` — shared helpers (`centaur_emit_metric`, file
  detection, JSON escape) used by every script.

### Changed

- `centaur-check` exits non-zero when risk meets `CENTAUR_FAIL_ON`
  (default `high`). Pre-commit hooks and CI rely on this. Plain text
  output is unchanged.
- `.centaur/metrics.jsonl` is now touched by `centaur-init`.
- Runtime README template documents the metrics schema.

### Notes

- No remote telemetry. Metrics stay in `<repo>/.centaur/metrics.jsonl`.
- Tree-sitter integration is deferred. The current `--ast` mode covers
  Python via the standard library and uses lightweight comment/string
  stripping for other languages.

## 0.1.0

- Initial public preview: skills (`centaur-init`, `centaur-contract`,
  `centaur-check`, `centaur-coach`, `centaur-health`, `centaur-drill`),
  deterministic shell scripts, templates, manual validation.
