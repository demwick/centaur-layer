---
name: centaur-drill
description: Run an opt-in synthetic review drill that trains developers to spot flawed AI suggestions without writing defects into real project files.
---

# Centaur Drill

Run a safe review drill.

## Workflow

1. Confirm the user asked for a drill or training exercise.
2. Run one of:

   ```bash
   bash "${CODEX_PLUGIN_ROOT:-.}/scripts/centaur-drill.sh" boundary
   bash "${CODEX_PLUGIN_ROOT:-.}/scripts/centaur-drill.sh" inverted-condition
   bash "${CODEX_PLUGIN_ROOT:-.}/scripts/centaur-drill.sh" null-handling
   ```

3. Show the synthetic snippet and ask the user to identify the flaw.
4. After the user answers, compare with the expected finding.

## Rules

- This mode is opt-in only.
- Never modify real project files.
- Always state that the snippet is synthetic training material.
- Do not call this "bug injection" in user-facing output.

## Output

Lead with:

`CENTAUR DRILL: synthetic`

Then show the prompt, snippet, and after the user's answer, the expected finding.
