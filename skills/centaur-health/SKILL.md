---
name: centaur-health
description: Audit whether a repository is ready for safe AI-assisted development by checking policy, contract, tests, verification, guardrails, and review discipline.
---

# Centaur Health

Audit AI-readiness for the current repository.

## Checks

Inspect for:

1. Centaur contract: `.centaur/contract.md`
2. Project policy: `CLAUDE.md` or `.claude/knowledge/charter/`
3. Architecture context: `.claude/knowledge/context/` or equivalent docs
4. Test runner presence
5. Review or verification command
6. Dangerous-operation guardrails
7. Git cleanliness
8. Optional SEA state: `.sea/`
9. Evidence that AI-generated work is verified, not blindly accepted

## Scoring

Return:

- `READY`: enough guardrails for routine AI-assisted work
- `PARTIAL`: usable, but important gaps exist
- `RISKY`: AI changes should be tightly supervised until gaps are closed

## Rules

- This is a local structural audit, not a security certification.
- Prefer concrete missing files, commands, and practices over broad advice.
- If `claude-charter` exists, use its health model as an input, but do not require it.

## Output

Lead with:

`CENTAUR HEALTH: READY | PARTIAL | RISKY`

Then list the top 3 fixes that would most improve human oversight.
