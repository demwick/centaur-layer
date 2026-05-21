# Testing

Centaur Layer has no build step. Validate the plugin structure with local commands.

```bash
bash scripts/validate-plugin.sh
```

Manual smoke test:

1. Load the plugin in a throwaway repository.
2. Run `centaur-init`.
3. Confirm `.centaur/contract.md`, `.centaur/README.md`, `CLAUDE.md`, and `.gitignore` exist.
4. Make a small diff.
5. Run `centaur-check` and confirm it asks diff-specific questions.
6. Run `centaur-health` and confirm it reports concrete missing guardrails.
7. Run `centaur-drill` and confirm it uses synthetic snippets only.

Deterministic script smoke tests:

```bash
tmp="$(mktemp -d)"
git -C "$tmp" init
bash scripts/centaur-init.sh "$tmp"
bash scripts/centaur-health.sh "$tmp"
bash scripts/centaur-drill.sh boundary
```
