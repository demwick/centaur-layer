# .centaur

This directory stores the local Centaur Layer contract and runtime state for this repository.

## Commit These

- `contract.md` — the human/AI working agreement for this project.

## Do Not Commit These

- `metrics.jsonl` — local interaction and review events.
- `session.json` — transient session state.

## Metrics Schema

Each line of `metrics.jsonl` is a single JSON object:

```json
{"ts":"2026-05-22T00:00:00Z","event":"check","risk":"high","files":3,"primary_reason":"..."}
```

Event types: `init`, `check`, `health`, `drill`. Summarize with `centaur-stats`.

Centaur Layer treats `.claude/` and `.sea/` as optional integrations. This directory is the only required Centaur state.
