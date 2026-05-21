# Centaur Layer

> Keep human judgment active while coding with AI.

![Centaur Layer social preview](docs/assets/social-preview.png)

Centaur Layer is a reasoning-preservation layer for AI-assisted software development. It helps developers use AI coding assistants without surrendering architectural judgment, code review discipline, or debugging skill.

AI coding agents make implementation faster. Centaur Layer focuses on the quieter failure mode: accepting generated code without understanding its risk.

## Status

Public preview / local MVP.

Centaur Layer is currently a local Codex plugin with deterministic shell scripts and skill instructions. It is ready for experimentation, feedback, and small-team trials, but it is not an enterprise governance platform.

## What It Does

Centaur Layer adds a lightweight coaching and review layer around AI coding workflows:

- **Centaur Contract** defines what the human owns, what AI may do, and which changes require explicit confirmation.
- **Centaur Check** reviews the current diff, reports deterministic risk signals, and prompts short comprehension checks before acceptance.
- **Centaur Coach** uses Socratic debugging instead of immediately pasting the final answer.
- **Centaur Health** audits structural readiness for AI-assisted development: policy, context, verification commands, guardrails, and git state.
- **Centaur Drill** runs synthetic review exercises without writing defects into real project files.

The guiding rule:

> AI may accelerate implementation, but the human keeps ownership of intent, tradeoffs, risk, and final judgment.

## Quick Demo

Dependency changes are treated as high-risk unless they include enough verification evidence:

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
```

Small documentation changes stay low-friction:

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

## Install Locally

Install from a local Codex plugin marketplace that points at this repository:

```bash
codex plugin list --marketplace <your-local-marketplace>
codex plugin add centaur-layer --marketplace <your-local-marketplace>
```

For direct script testing from a clone:

```bash
git clone https://github.com/demwick/centaur-layer.git
cd centaur-layer
bash scripts/validate-plugin.sh
```

## First Use

Initialize Centaur state in a target repository:

```bash
bash /path/to/centaur-layer/scripts/centaur-init.sh /path/to/target-repo
```

This creates:

- `.centaur/contract.md`
- `.centaur/README.md`
- `CLAUDE.md`
- `.gitignore` entries for local runtime state

Commit initialization separately from product changes:

```bash
cd /path/to/target-repo
git add .centaur .gitignore CLAUDE.md
git commit -m "chore: initialize centaur"
```

Then use the plugin skills:

```text
Use centaur-contract before implementing the next feature.
Use centaur-check on the current diff.
Use centaur-coach to debug this failing test.
Use centaur-health to audit AI-readiness.
Use centaur-drill for a synthetic review drill.
```

## Why This Exists

AI coding assistants do not only introduce code risk. They also introduce review risk: the developer may stop tracing assumptions, edge cases, and ownership boundaries.

Centaur Layer is designed to keep that reasoning loop alive:

- contracts before work starts
- deterministic risk signals before code is accepted
- short comprehension checks instead of performative review ceremony
- verification evidence before success is reported
- synthetic drills only, never deliberate defects written into real code

Deliberate defect drills should be opt-in, sandbox-only, and never written into production project files.

## Relationship To Other Projects

Centaur Layer is the single product users install.

It borrows proven ideas from two companion projects without requiring users to install them separately:

| Source | What Centaur Uses |
|---|---|
| `claude-charter` | layered policy, trust boundaries, guardrails, self-audit |
| `software-engineer-agents` | scoped execution, risk gates, verification discipline, atomic work |

If a project already has `.claude/` charter files or `.sea/` state, Centaur can read and respect them. They are optional integrations, not required dependencies.

## Validation

Validate the local plugin structure with:

```bash
bash scripts/validate-plugin.sh
```

The validation command smoke-tests `centaur-init`, `centaur-health`, `centaur-check`, and `centaur-drill` in temporary git repositories.

## Roadmap

- Exercise the plugin inside real Codex sessions against throwaway apps.
- Improve `centaur-contract` so it can update the Active Contract section safely.
- Add richer diff parsing once file-path heuristics prove useful.
- Explore JSON output for agent-friendly integrations.
- Keep training drills synthetic-only until there is a trusted IDE preview flow.

## License

MIT
