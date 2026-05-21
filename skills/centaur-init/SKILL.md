---
name: centaur-init
description: Initialize Centaur Layer in a repository by creating a human/AI responsibility contract, detecting optional claude-charter and SEA state, and preparing local Centaur runtime files.
---

# Centaur Init

Initialize Centaur Layer for the current repository.

## Workflow

1. Inspect the repository root.
2. Detect optional integrations:
   - `.claude/` or `CLAUDE.md` means a charter-style policy layer exists.
   - `.sea/` means a software-engineer-agents runtime state exists.
3. Create `.centaur/` if needed.
4. Create `.centaur/contract.md` from the template below if it does not exist.
5. Create `.centaur/README.md` from `templates/runtime-readme.md` with a short explanation of committed vs ignored Centaur files.
6. Add `.centaur/metrics.jsonl` and `.centaur/session.json` to `.gitignore` if they are not already ignored.
7. Report what was detected and the next recommended command.

## Rules

- Do not overwrite an existing `.centaur/contract.md` without explicit user approval.
- Do not require `claude-charter` or `software-engineer-agents`; treat them as optional integrations.
- Keep initialization small. No scaffolding, no dependency installs, no git commits.
- If the repository is dirty, preserve all existing work.
- Commit `.centaur/contract.md`; do not commit runtime metrics.
- If `.gitignore` does not exist, create it.

## Contract Template

Use this exact structure for a new `.centaur/contract.md`:

```markdown
# Centaur Contract

AI may accelerate implementation, but the human owns intent, tradeoffs, risk, and final judgment.

## Repository Defaults

### Human Owns

- product intent and acceptance criteria
- architecture and data model decisions
- security, privacy, and permission tradeoffs
- final review of risky diffs

### AI May Do

- inspect repository structure
- propose plans and implementation options
- edit code inside approved scope
- write and run tests
- summarize tradeoffs and residual risk

### Requires Explicit Confirmation

- schema migrations
- auth, permission, billing, or secrets changes
- destructive filesystem or git operations
- dependency removal or major version changes
- broad refactors across module boundaries

### Verification Required

- relevant tests, lint, typecheck, or build command
- explanation of changed behavior
- known residual risk

## Active Contract

### Goal

Unset.

### Human Owns

- Unset.

### AI May Do

- Unset.

### Out Of Scope

- Unset.

### Risk Gates

- Unset.

### Acceptance Checks

- Unset.
```

## Output

End with:

- contract path
- detected integrations
- recommended next step, usually `centaur-contract`
