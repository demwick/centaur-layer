---
name: centaur-contract
description: Create or update a Centaur Contract that defines what the human owns, what AI may do, risk gates, review expectations, and coaching mode for a feature or repository.
---

# Centaur Contract

Define the human/AI division of responsibility before implementation starts.

## Contract Fields

A useful contract answers:

- What outcome are we trying to achieve?
- Which decisions belong to the human?
- Which implementation tasks may AI perform?
- Which files or domains are in scope?
- Which actions require explicit confirmation?
- What verification proves the work is acceptable?
- When should Centaur use coaching instead of direct answers?

## Workflow

1. Read `.centaur/contract.md` if present.
2. Read nearby policy sources if present:
   - `CLAUDE.md`
   - `.claude/knowledge/charter/`
   - `.claude/knowledge/context/`
3. Summarize the current contract in plain language.
4. If the user asks for a new feature contract, write a scoped section under `## Active Contract`.
5. Prefer concrete boundaries over abstract intent.

## Risk Gates

Require explicit confirmation for:

- schema migrations
- auth, permissions, secrets, or billing changes
- destructive filesystem or git actions
- broad refactors touching more than three modules
- dependency removal or major version changes
- generated code that the user cannot explain

## Output

Report the resulting division of responsibility:

- Human owns
- AI may do
- Requires confirmation
- Verification required
