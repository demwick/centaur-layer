# CLAUDE.md

This project uses Centaur Layer to keep human judgment active while working with AI coding assistants.

## Centaur Principles

- The human owns intent, architecture, tradeoffs, and final acceptance.
- AI may inspect, propose, implement inside approved scope, and help verify.
- Risky changes require explicit confirmation before acceptance.
- Generated code must be read, understood, and verified before it is committed.

## Required Behavior

- Read the relevant files before editing.
- Keep changes scoped to the active task.
- Preserve unrelated user work.
- Run the narrowest meaningful verification command before reporting success.
- For auth, permissions, secrets, schema, dependency, or destructive changes, stop and ask for confirmation.

## Verification

When reporting a completed change, include:

- what changed
- what was verified
- what risk remains
