# Testing

Centaur Layer has no build step. Validate the plugin structure with local commands.

```bash
python3 -m json.tool .codex-plugin/plugin.json >/dev/null

for f in skills/*/SKILL.md; do
  head -1 "$f" | grep -q '^---$'
done
```

Manual smoke test:

1. Load the plugin in a throwaway repository.
2. Run `centaur-init`.
3. Confirm `.centaur/contract.md` exists and `.gitignore` ignores runtime metrics.
4. Make a small diff.
5. Run `centaur-check` and confirm it asks diff-specific questions.
6. Run `centaur-health` and confirm it reports concrete missing guardrails.

