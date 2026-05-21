# Centaur Layer

> A reasoning-preservation layer for AI-assisted software development.

Centaur Layer helps developers use AI coding assistants without surrendering architectural judgment, code review discipline, or debugging skill. It turns AI from an autopilot into a training partner: fast where speed helps, interruptive where human reasoning must stay awake.

## What It Is

Centaur Layer is a Codex plugin that adds a lightweight coaching and governance layer above AI coding workflows.

It is designed around one idea:

> AI may accelerate implementation, but the human keeps ownership of intent, tradeoffs, risk, and final judgment.

## Relationship To Other Projects

Centaur Layer is the single product users install.

It borrows proven ideas from two companion projects without requiring users to install them separately:

| Source | What Centaur Uses |
|---|---|
| `claude-charter` | layered policy, trust boundaries, guardrails, self-audit |
| `software-engineer-agents` | scoped execution, risk gates, verification discipline, atomic work |

If a project already has `.claude/` charter files or `.sea/` state, Centaur can read and respect them. They are optional integrations, not required dependencies.

## Core Modes

### Centaur Contract

Defines the human/AI division of responsibility before work begins.

Examples:

- human owns architecture and data model decisions
- AI may implement UI and tests inside approved paths
- schema migrations require explicit approval
- high-risk diffs require a comprehension check before acceptance

### Centaur Check

Reviews the current diff and asks short reasoning questions before the user accepts AI-generated work.

Examples:

- What is the highest-risk edge case in this change?
- Which test should fail if this implementation is wrong?
- What assumption does this code make about external input?

### Centaur Coach

Uses a Socratic debugging style. Instead of pasting the final fix immediately, it guides the developer through observations, hypotheses, and verification.

### Centaur Health

Audits whether the project has enough policy, context, guardrails, tests, and review discipline to use AI safely.

## Why Not Start With Deliberate Bug Injection?

Intentional challenge variants are powerful, but trust-sensitive. The first version uses safe comprehension checks over real diffs. Deliberate defect drills should be opt-in, sandbox-only, and never written to disk.

## Install Locally

From this repository:

```bash
codex plugin install .
```

Or load it from a local marketplace entry once published.

## First Use

```text
Use centaur-init in this repo.
Use centaur-contract before implementing the next feature.
Use centaur-check on the current diff.
Use centaur-coach to debug this failing test.
Use centaur-health to audit AI-readiness.
```

For a concrete contract shape, see `examples/contracts/web-feature.md`.

## Project Status

MVP scaffold. The first goal is a usable local plugin with contract creation, diff comprehension checks, Socratic coaching, and health audit prompts.

Validate the local plugin structure with:

```bash
bash scripts/validate-plugin.sh
```

## Near-Term Roadmap

1. Make `centaur-init` create a useful `.centaur/contract.md` in real repos.
2. Make `centaur-check` produce risk-specific questions from actual diffs.
3. Add optional detection for `.claude/` charter policy and `.sea/` execution state.
4. Add an opt-in training drill mode that uses synthetic diffs only.
