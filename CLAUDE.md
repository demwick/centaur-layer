# CLAUDE.md

This repository contains the Centaur Layer plugin (ships as both a Codex plugin and a Claude Code plugin from the same source).

## Product Direction

Centaur Layer is the single installable product. It may borrow ideas from `claude-charter` and `software-engineer-agents`, but users should not need to install those projects separately.

Keep the product centered on one promise: AI can accelerate coding without weakening the developer's reasoning, review discipline, or ownership of risky decisions.

## Engineering Rules

- Keep the MVP small: contract, check, coach, health.
- Do not add remote telemetry.
- Do not write deliberate defect drills into real project files.
- Treat `.claude/` and `.sea/` as optional integrations.
- Prefer clear skill instructions over custom runtime code until the workflow proves it needs scripts.
- Every new skill should say when it stops, when it asks, and what evidence it reports.

## Validation

Run:

```bash
bash scripts/validate-plugin.sh
```

Manual testing guidance lives in `TESTING.md`.
