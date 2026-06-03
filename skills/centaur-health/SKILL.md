---
name: centaur-health
description: Audit whether a repository is ready for safe AI-assisted development by checking policy, contract, tests, verification, guardrails, and review discipline.
---

# Centaur Health

Audit structural AI-readiness for the current repository.

## Checks

Run:

```bash
bash "${CLAUDE_PLUGIN_ROOT:-${CODEX_PLUGIN_ROOT:-.}}/scripts/centaur-health.sh" .
```

Then use the script output as the evidence base. The script inspects:

1. Centaur contract: `.centaur/contract.md`
2. Project policy: `CLAUDE.md` or `.claude/knowledge/charter/`
3. Architecture context: `.claude/knowledge/context/` or equivalent docs
4. Test runner presence
5. Review or verification command signal
6. Dangerous-operation guardrails
7. Git cleanliness
8. Optional software-engineer state: `.se/`
9. Centaur policy language in `CLAUDE.md`

## Scoring

Return:

- `READY`: enough guardrails for routine AI-assisted work
- `PARTIAL`: usable, but important gaps exist
- `RISKY`: AI changes should be tightly supervised until gaps are closed

## Rules

- This is a local structural audit, not a security certification.
- This does not prove AI-generated work is actually reviewed; it reports local files and commands that support that practice.
- Prefer concrete missing files, commands, and practices over broad advice.
- If `claude-charter` exists, use its health model as an input, but do not require it.
- Do not upgrade the status beyond what the script reports.

## Output

Lead with:

`CENTAUR HEALTH: READY | PARTIAL | RISKY`

Then report:

- `Signals`
- `Top fixes`
- `Suggested next command`

Keep the status and next command aligned with the script output.
