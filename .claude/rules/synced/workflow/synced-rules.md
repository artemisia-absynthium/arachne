# Synced rules

Files under `.claude/rules/synced/` are auto-managed — never edit them directly.
A hook will block the attempt; edits would be overwritten by the next sync anyway.

- **Project-specific rules** → create them directly in `.claude/rules/` (never touched by sync)
- **Opt a category out** → comment the category line in `.claude/rules-sync.txt`; it won't be re-added
- **Generalize a pattern upstream** → use the `lift-to-shared-rules` skill (see `contributing.md`)
