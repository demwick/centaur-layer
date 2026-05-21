---
name: centaur-check
description: Review the current diff or proposed AI change and run a short comprehension check that keeps the developer actively reasoning before accepting generated code.
---

# Centaur Check

Run a reasoning check on a diff before it is accepted.

## Workflow

1. Run:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT:-${CODEX_PLUGIN_ROOT:-.}}/scripts/centaur-check.sh" .
   ```

2. Read the script output.
3. If the script reports no diff, stop and suggest `centaur-contract` or `centaur-coach`.
4. If the script reports a diff, treat the listed questions as baseline questions.
5. Read the changed files or diff hunks only as needed to ground the check.
6. Add at most one extra question only if local context reveals a concrete missed risk.
7. Recommend accept, revise, or verify further.

## Risk Rubric

- **low**: docs, copy, tests, small local refactors, or isolated UI changes with clear verification.
- **medium**: behavior changes, new branches, error handling, async flows, data parsing, mixed setup/product diffs, or changes touching 2-3 modules.
- **high**: auth, permissions, secrets, billing, persistence, schema migrations, generated code the user cannot explain, destructive operations, or broad cross-module refactors.

## Question Style

Good questions are specific and check reasoning:

- Which input shape could break this branch?
- What test would fail if this assumption is wrong?
- What user-visible behavior changed here?
- Which part of the contract does this diff rely on?

Prefer questions that name the relevant file, function, branch, input shape, or contract assumption. Avoid trivia questions, generic quizzes, and repeating the script's baseline questions.

## Rules

- Do not invent issues. Anchor every question in an observed diff, contract, or test gap.
- Do not block low-risk changes with performative ceremony.
- If there is no diff, say so and suggest `centaur-contract` or `centaur-coach` depending on intent.
- Never write challenge defects to disk.
- For high-risk diffs, require the user to state the intended behavior and the verification command before recommending acceptance.
- If tests were not run, make that explicit in the recommendation.
- Do not downgrade the risk below what `scripts/centaur-check.sh` reports.
- Use `Diff signals` as deterministic evidence, not as a substitute for reading the relevant diff when adding a concrete question.
- If you cannot identify a concrete missed risk, ask only the script's baseline questions.

## Output

Lead with the risk level:

`CENTAUR CHECK: low | medium | high`

Then provide:

- `Modified files`
- `Staged files`
- `Untracked files`
- `Risk reasons`
- `Diff signals`
- `Questions`
- `Verification`
- `Recommendation`
