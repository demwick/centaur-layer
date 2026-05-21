---
name: centaur-install-hooks
description: Install a Centaur Layer pre-commit hook that runs centaur-check on the staged diff and blocks commits when risk exceeds the configured threshold.
---

# Centaur Install Hooks

Wire Centaur Layer into the local git workflow so the human doesn't have to remember to run `centaur-check` before every commit.

## When To Use

- After `centaur-init`, when the user wants automatic risk gating on commits.
- When a teammate is sharing a repo and wants the same guard active locally.
- Not required for AI-assisted work — Centaur stays useful without it.

## Workflow

1. Confirm the user wants the hook installed (it changes `.git/hooks/pre-commit`).
2. Run:

   ```bash
   bash "${CODEX_PLUGIN_ROOT:-.}/scripts/centaur-install-hooks.sh" .
   ```

3. Read the script output.
4. Report install state, threshold, and how to bypass.

## Rules

- The hook is local. Each contributor must install it for themselves; do not commit it.
- If a non-Centaur `pre-commit` already exists, the script backs it up with a `.centaur-backup.<ts>` suffix.
- Default threshold is high. To change for the next commit: `CENTAUR_FAIL_ON=medium git commit ...`.
- To bypass once (for a deliberate override): `git commit --no-verify`.
- Never override silently; the human should know why a high-risk commit was force-accepted.
- Hooks call `centaur-check --staged`. Working-tree-only changes are ignored on purpose.

## Output

Report:

- where the hook was installed
- the active threshold
- override instructions
- backup path if an existing hook was preserved
