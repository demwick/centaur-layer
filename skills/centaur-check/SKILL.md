---
name: centaur-check
description: Review the current diff or proposed AI change and run a short comprehension check that keeps the developer actively reasoning before accepting generated code.
---

# Centaur Check

Run a reasoning check on a diff before it is accepted.

## Workflow

1. Run:

   ```bash
   bash "${CODEX_PLUGIN_ROOT:-.}/scripts/centaur-check.sh" .
   ```

2. Read the script output.
3. If the script reports no diff, stop and suggest `centaur-contract` or `centaur-coach`.
4. If the script reports a diff, ask the listed questions and add at most one extra question only if local context reveals a concrete missed risk.
5. Recommend accept, revise, or verify further.

## Risk Rubric

- **low**: docs, copy, tests, small local refactors, or isolated UI changes with clear verification.
- **medium**: behavior changes, new branches, error handling, async flows, data parsing, dependency bumps, or changes touching 2-3 modules.
- **high**: auth, permissions, secrets, billing, persistence, schema migrations, generated code the user cannot explain, destructive operations, or broad cross-module refactors.

## Question Style

Good questions are specific and check reasoning:

- Which input shape could break this branch?
- What test would fail if this assumption is wrong?
- What user-visible behavior changed here?
- Which part of the contract does this diff rely on?

Avoid trivia questions and generic quizzes.

## Rules

- Do not invent issues. Anchor every question in an observed diff, contract, or test gap.
- Do not block low-risk changes with performative ceremony.
- If there is no diff, say so and suggest `centaur-contract` or `centaur-coach` depending on intent.
- Never write challenge defects to disk.
- For high-risk diffs, require the user to state the intended behavior and the verification command before recommending acceptance.
- If tests were not run, make that explicit in the recommendation.
- Do not downgrade the risk below what `scripts/centaur-check.sh` reports.

## Output

Lead with the risk level:

`CENTAUR CHECK: low | medium | high`

Then provide:

- `Observed change`
- `Questions`
- `Verification`
- `Recommendation`
