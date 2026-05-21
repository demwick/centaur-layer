# Centaur Layer

[![CI](https://img.shields.io/github/actions/workflow/status/demwick/centaur-layer/centaur-self-check.yml?label=CI&logo=github)](https://github.com/demwick/centaur-layer/actions)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-D97757?logo=anthropic&logoColor=white)](https://docs.claude.com/en/docs/claude-code/plugins)
[![Codex](https://img.shields.io/badge/Codex-plugin-10A37F?logo=openai&logoColor=white)](https://developers.openai.com/codex)
[![No telemetry](https://img.shields.io/badge/telemetry-none-brightgreen)](#)

> Keep human judgment active while coding with AI.

![Centaur Layer social preview](docs/assets/social-preview.png)

Centaur Layer is a reasoning-preservation layer for AI-assisted software development. It is a small, local Codex plugin that wraps your existing AI coding workflow with contracts, deterministic diff risk signals, Socratic debugging, and AI-readiness audits — so the human stays in the loop on intent, tradeoffs, and risk.

AI agents make implementation faster. Centaur Layer targets the quieter failure mode: **accepting generated code without understanding its risk.**

---

## Inspiration & The Centaur Concept

The name and design philosophy come from two places.

**Garry Kasparov — Centaur Chess.** After losing to Deep Blue in 1997, Kasparov did not retreat from machines. He invented "Advanced Chess" (later called *centaur chess*): a human player paired with a chess engine. The interesting finding from years of centaur tournaments was that **a strong human + a weak machine + a good process consistently beat both grandmasters and supercomputers playing alone**. The process — the human's questions, doubts, and judgment over the machine's suggestions — was the moat, not raw computation.

**Barış Özcan — "Are you using AI, or is it using you?".** In his video essay *(Sen mi Yapay Zeka Kullanıyorsun? Yoksa O mu Seni?)*, Özcan frames two modes of working with AI: the **Cyborg** and the **Centaur**.

- The **Cyborg** fuses with the tool. Speed feels great. But over time the human's reasoning atrophies — the cognitive muscles you stop using get weaker. One day you realize you cannot architect, debug, or even *evaluate* the model's output without it. You have fallen asleep at the wheel.
- The **Centaur** stays a distinct rider. The machine carries velocity, the human carries judgment. They are partners, not one organism. The Centaur stays sharp because they keep doing the parts that matter — defining intent, naming risk, owning the final call.

**The Core Problem: Review Risk.** AI coding assistants do not only introduce code risk; they introduce *review risk*. The developer may stop tracing assumptions, edge cases, and ownership boundaries. The diff still gets merged. The bug shows up three weeks later in a domain no one re-read.

Centaur Layer is engineering scaffolding for staying the Centaur and mitigating review risk:

- contracts make the boundary between rider and horse explicit
- risk signals refuse to let dependency or auth changes slip through unreviewed
- comprehension checks force a brief moment of "do I actually understand this?" before acceptance
- Socratic coaching resists the urge to paste the answer and skip the thinking

The guiding rule:

> AI may accelerate implementation, but the human keeps ownership of intent, tradeoffs, risk, and final judgment.

---

## Status

Public preview / local MVP. Centaur Layer is a Codex plugin with deterministic shell scripts and skill instructions. It is ready for experimentation, feedback, and small-team trials. It is not an enterprise governance platform, and it does not phone home.

---

## What It Does

| Skill | Purpose |
|---|---|
| `centaur-init` | Bootstrap a contract, policy file, and runtime state in a target repo. |
| `centaur-contract` | Define what the human owns, what AI may do, and which changes need confirmation. |
| `centaur-check` | Score the current diff (low / medium / high) and ask short, targeted comprehension questions. |
| `centaur-coach` | Socratic debugging — guides reasoning instead of pasting the final answer. |
| `centaur-health` | Audit AI-readiness: policy, contract, verification commands, guardrails, git state. |
| `centaur-drill` | Opt-in synthetic review drills — *never* writes defects into real files. |
| `centaur-install-hooks` | Install a local pre-commit hook that blocks high-risk diffs. |
| `centaur-stats` | Summarize local usage (checks, drills, health audits) from `.centaur/metrics.jsonl`. |

---

## Quick Demo

A dependency change without lockfile evidence is gated as **high risk** — the questions are specific, and the script exits non-zero so a pre-commit hook or CI can block it:

```text
CENTAUR CHECK: high

Modified files:
- package.json

Risk reasons:
- dependency or build metadata changed: package.json
- dependency metadata changed without lockfile evidence

Diff signals:
- files_changed: 1
- dependency_manifest_changed: yes
- lockfile_evidence: no
- test_runner: detected

Questions:
- What behavior is intended to change, and what must remain unchanged?
- Which command proves this change is safe enough to accept?
- Which edge case would be most expensive to miss here?

Verification:
- Required before acceptance: state intended behavior and run the relevant verification command.

Recommendation:
- Revise or verify before accepting this AI-generated change.
```

A small documentation change stays low-friction — no ceremony, no blocking:

```text
CENTAUR CHECK: low

Modified files:
- README.md

Diff signals:
- files_changed: 1
- docs_files_changed: yes
- dependency_manifest_changed: no

Recommendation:
- Accept only after the questions above have clear answers.
```

The same script powers the local pre-commit hook and the bundled GitHub Action — same signals on the dev's laptop and in CI.

---

## Prerequisites

Centaur Layer is intentionally low-dependency. You need:

- **A skill-capable CLI** — Centaur Layer is shipped as both a **Codex plugin** and a **Claude Code plugin**. Either CLI can invoke the skills (`centaur-check`, `centaur-contract`, etc.) conversationally. Without one of them you can still run the underlying shell scripts directly (see *Direct Script Use* below), but you lose the skill layer.
- **bash** ≥ 4 (the scripts assume `set -euo pipefail`, arrays, and `<<<`)
- **git** — required by `centaur-check` and `centaur-health`; both refuse to run useful work outside a git worktree
- **python3** — only used by `scripts/validate-plugin.sh` for JSON manifest validation
- **macOS or Linux** — date math in `centaur-stats` supports both BSD (`date -v`) and GNU (`date -d`) variants

No network access is required at runtime. No telemetry is sent anywhere — metrics are written only to `<repo>/.centaur/metrics.jsonl` and stay on disk.

---

## Install

Centaur Layer ships with two plugin manifests in the same repo:

- `.codex-plugin/plugin.json` — Codex CLI
- `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` — Claude Code CLI

Skills are identical across both. Internally the skills resolve their script path against `${CLAUDE_PLUGIN_ROOT:-${CODEX_PLUGIN_ROOT:-.}}`, so whichever CLI is running, paths just work.

### As a Codex plugin

Remote install via the GitHub shorthand:

```bash
codex plugin marketplace add demwick/centaur-layer
codex plugin add centaur-layer@centaur-layer
codex plugin list
```

Or, from a local clone:

```bash
git clone https://github.com/demwick/centaur-layer.git ~/.centaur/plugin
codex plugin marketplace add ~/.centaur/plugin
codex plugin add centaur-layer@centaur-layer
```

Codex exposes the skills (`centaur-init`, `centaur-check`, …) and sets `${CODEX_PLUGIN_ROOT}` to the plugin path.

### As a Claude Code plugin

The repo is its own single-plugin marketplace. Inside a Claude Code session:

```text
/plugin marketplace add demwick/centaur-layer
/plugin install centaur-layer@centaur-layer
```

Or, from a local clone:

```bash
git clone https://github.com/demwick/centaur-layer.git ~/.centaur/plugin
```

```text
/plugin marketplace add ~/.centaur/plugin
/plugin install centaur-layer@centaur-layer
```

Claude Code sets `${CLAUDE_PLUGIN_ROOT}` to the plugin path and exposes the same skills.

### Direct script use (no CLI)

Every skill is a thin wrapper around a deterministic script. You can run the scripts straight from a clone — useful for CI, hooks, or sanity-checking the plugin:

```bash
git clone https://github.com/demwick/centaur-layer.git
cd centaur-layer
bash scripts/validate-plugin.sh   # smoke-test init, health, check, drill
```

---

## First Use

Initialize Centaur state in a target repository:

```bash
bash /path/to/centaur-layer/scripts/centaur-init.sh /path/to/target-repo
```

Add `--with-hooks` to install the pre-commit hook in the same step:

```bash
bash /path/to/centaur-layer/scripts/centaur-init.sh --with-hooks /path/to/target-repo
```

`centaur-init` creates (and never overwrites):

- `.centaur/contract.md` — the human/AI working agreement
- `.centaur/README.md` — runtime notes for the local Centaur state
- `CLAUDE.md` — policy language the assistant must respect
- `.centaur/metrics.jsonl` — local-only usage log
- `.gitignore` entries for runtime files (`metrics.jsonl`, `session.json`)

It also probes for optional integrations (`.claude/knowledge/charter/`, `.sea/`) and reports whether they were detected. Neither is required.

Commit the initialization separately from product changes:

```bash
cd /path/to/target-repo
git add .centaur CLAUDE.md .gitignore
git commit -m "chore: initialize centaur"
```

Then, inside a Codex session, drive the skills conversationally:

```text
Use centaur-contract to define scope for the next feature.
Use centaur-check on the current diff.
Use centaur-coach to debug this failing test.
Use centaur-health to audit AI-readiness.
Use centaur-drill boundary for a synthetic review drill.
Use centaur-stats to summarize the last 7 days.
```

---

## Command Reference

All scripts live under `scripts/` and accept an optional target directory (defaulting to `.`):

```bash
bash scripts/centaur-init.sh           [--with-hooks]            [<dir>]
bash scripts/centaur-check.sh          [--staged|--all] [--ast]  [<dir>]
bash scripts/centaur-health.sh                                   [<dir>]
bash scripts/centaur-drill.sh          <boundary|inverted-condition|null-handling>
bash scripts/centaur-install-hooks.sh                            [<dir>]
bash scripts/centaur-stats.sh          [--days N]                [<dir>]
bash scripts/centaur-ast-check.sh      <file> [<file> ...]
bash scripts/validate-plugin.sh
```

Notable flags:

- `centaur-check --staged` — score only staged files (this is what the pre-commit hook and GitHub Action use).
- `centaur-check --all` — include modified, staged, and untracked files (default).
- `centaur-check --ast` — use Python's `ast` module (and comment/string stripping for other languages) to confirm sensitive-domain matches. Downgrades false positives where the filename has a sensitive keyword but the content does not.
- `centaur-stats --days N` — change the lookback window from the 7-day default.

---

## Optional Integrations

### Pre-commit hook

Install the hook to block high-risk diffs locally:

```bash
bash scripts/centaur-install-hooks.sh /path/to/target-repo
```

The hook:

- runs `centaur-check --staged` on every commit
- exits non-zero (blocks the commit) when risk meets the threshold (`high` by default)
- backs up any existing `pre-commit` hook to `pre-commit.centaur-backup.<timestamp>`

Override the threshold for a single commit:

```bash
CENTAUR_FAIL_ON=medium git commit -m "..."
```

Bypass once (with full ownership of the override):

```bash
git commit --no-verify
```

The hook is local — each contributor installs it for themselves. It is intentionally not committed to the repo.

### GitHub Action

Copy `templates/github-action.yml` to `.github/workflows/centaur-check.yml` to gate pull requests with the same risk signals and post the report as a PR comment. Set repository variable `CENTAUR_FAIL_ON` (default `high`) to control when the job fails.

---

## Configuration

| Variable | Used by | Default | Effect |
|---|---|---|---|
| `CENTAUR_FAIL_ON` | `centaur-check`, pre-commit hook, GitHub Action | `high` | Exit non-zero at this risk level or above. Values: `none`, `low`, `medium`, `high`. |
| `CENTAUR_AST` | `centaur-check` | `0` | Set to `1` to default-enable AST-confirmed sensitive-domain checks (same as `--ast`). |
| `CENTAUR_METRICS_DISABLED` | all scripts | unset | Set to `1` to suppress writes to `.centaur/metrics.jsonl`. |
| `CENTAUR_PLUGIN_ROOT` | pre-commit hook template | unset | Tells the hook where to find `scripts/centaur-check.sh` outside a CLI session. |
| `CLAUDE_PLUGIN_ROOT` | skill files | set by Claude Code | Skill commands resolve script paths against this first. |
| `CODEX_PLUGIN_ROOT` | skill files | set by Codex | Fallback when `CLAUDE_PLUGIN_ROOT` is unset. |

---

## Risk Rubric

`centaur-check` maps diff signals to one of three levels:

- **low** — docs, copy, isolated tests, small local refactors, UI tweaks with clear verification.
- **medium** — behavior changes, new branches, error handling, async flows, data parsing, mixed setup/product diffs, or anything touching 2–3 modules.
- **high** — auth, permissions, secrets, billing, persistence, schema migrations, dependency manifests without lockfile evidence, destructive operations, or generated code the human cannot explain.

The script never downgrades risk based on optimism — it only ever escalates when contract terms or sensitive-domain patterns match.

---

## Relationship To Other Projects

Centaur Layer is the single product you install. It borrows proven ideas from two companion projects without requiring you to install them separately:

| Source | What Centaur uses |
|---|---|
| `claude-charter` | layered policy, trust boundaries, guardrails, self-audit |
| `software-engineer-agents` | scoped execution, risk gates, verification discipline, atomic work |

If a project already has `.claude/` charter files or `.sea/` state, Centaur reads and respects them — but they are optional integrations, not dependencies.

---

## Validation & Testing

```bash
bash scripts/validate-plugin.sh
```

This parses the plugin manifest, smoke-tests `centaur-init`, `centaur-health`, `centaur-check`, and `centaur-drill` in temporary git repositories, and asserts that no real files are touched by drills. See [`TESTING.md`](TESTING.md) for manual scenarios.

---

## Roadmap

- Exercise the plugin in real Codex sessions against throwaway apps.
- Improve `centaur-contract` so it can safely update the Active Contract section in place.
- Richer diff parsing once file-path heuristics prove useful.
- JSON output mode for agent-friendly integrations.
- Keep training drills synthetic-only until there is a trusted IDE preview flow.

Non-goals (for now): IDE UI, deliberate bug injection into real code, enterprise dashboards, remote telemetry, replacing existing coding agents.

---

## Contributing & Feedback

This is a public preview. The most useful feedback is concrete:

- A diff your team merged that Centaur should have flagged but didn't.
- A check that felt like ceremony — what was the noise, what was the signal?
- A risk rubric mismatch — `high` when it should be `medium`, or vice versa.

Open an issue or a discussion on the [GitHub repository](https://github.com/demwick/centaur-layer).

---

## License

MIT
