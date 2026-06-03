# CLAUDE.md

This repository contains the Centaur Layer plugin (ships as both a Codex plugin and a Claude Code plugin from the same source).

## Product Direction

Centaur Layer is one of three independent, composable layers: `software-engineer` (the engine — how work gets done, runtime state in `.se/`), `claude-charter` (the constitution — rules and trust boundaries) and Centaur Layer (the brake — did the human understand the diff). Each works fully standalone; none requires the others.

The composition model is **Detect & Defer**: when Centaur detects another layer it defers that concern to it instead of duplicating it, but it never requires the other to be installed. Centaur's role in the ecosystem is to question the human, not the machine.

Keep the product centered on one promise: AI can accelerate coding without weakening the developer's reasoning, review discipline, or ownership of risky decisions.

## Engineering Rules

- Keep the MVP small: contract, check, coach, health.
- Do not add remote telemetry.
- Do not write deliberate defect drills into real project files.
- Treat `.claude/` and `.se/` as optional integrations.
- Prefer clear skill instructions over custom runtime code until the workflow proves it needs scripts.
- Every new skill should say when it stops, when it asks, and what evidence it reports.

## Validation

Run:

```bash
bash scripts/validate-plugin.sh
```

Manual testing guidance lives in `TESTING.md`.
