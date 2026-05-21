---
name: centaur-stats
description: Summarize local Centaur Layer usage (checks, drills, health audits, init events) from .centaur/metrics.jsonl over a recent window.
---

# Centaur Stats

Summarize local Centaur usage so the human can see whether the review and drill loop is actually running.

## When To Use

- Weekly reflection on whether AI-assisted changes are being checked.
- After a sprint, to count high-risk diffs that hit the contract.
- Before a release, to confirm the team exercised review skills.

## Workflow

Run:

```bash
bash "${CLAUDE_PLUGIN_ROOT:-${CODEX_PLUGIN_ROOT:-.}}/scripts/centaur-stats.sh" . --days 7
```

Then:

1. Read the script output.
2. Highlight the most concrete signal (e.g. zero checks this week, mostly high-risk, no drills).
3. Suggest one small follow-up command (often `centaur-drill <mode>` or `centaur-check`).

## Rules

- Do not invent numbers. The script output is the only source of truth.
- Do not export, share, or upload `.centaur/metrics.jsonl`. It is local-only.
- If metrics file is missing, suggest `centaur-init` rather than guessing.
- Treat zero counts as a useful signal, not a failure to report.
- Default window is 7 days; longer windows are reasonable for retros.

## Output

Lead with the window and totals, then per-event counts. Keep it short:

```
Centaur usage — last 7 days
- 23 checks (4 high, 8 medium, 11 low)
- 5 drills (boundary x3, null-handling x2)
- 2 health audits (last: READY)
Next: run centaur-drill on a mode you haven't covered this week.
```
