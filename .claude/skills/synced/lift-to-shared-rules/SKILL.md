# lift-to-shared-rules

Persist a generalizable coding pattern into the shared rules repo, verify coherence across all existing rules, show the diff with a filled-in acceptance checklist, and propose a commit+push (owner) or fork+PR (contributor).

Invoke this skill whenever a pattern, constraint, or convention emerges that should apply across all projects, not just the current one.

## Step 0 — Detect mode

Run the following checks and set mode before doing anything else:

```bash
echo "${CLAUDE_SETUP_PATH:-UNSET}"
[[ -n "$CLAUDE_SETUP_PATH" && -d "$CLAUDE_SETUP_PATH/.git" ]] && echo "DIR: OK" || echo "DIR: MISSING"
gh api repos/artemisia-absynthium/claude-setup --jq '.permissions.push' 2>/dev/null
```

- **Owner mode**: `CLAUDE_SETUP_PATH` is set, the directory exists, and push permission is `true`. Work is done directly in `$CLAUDE_SETUP_PATH`.
- **Contributor mode**: any condition fails — env var unset, directory missing, or no push access. State which condition triggered contributor mode, then proceed with the fork/PR flow (Step 6b).

## Step 1 — Identify target

Determine the category and file:

- Known categories: `swift`, `visionos`, `xcode`, `mac`, `android`, `web`, `workflow`
- Map the rule to the most specific applicable category
- Target file: `<repo>/rules/<category>/<topic>.md`
- If no existing file fits within a category, create a new one with a descriptive name
- If the rule belongs to a stack not yet represented (e.g. `python`, `java`), create the new category directory and add the file — do not force-fit it into an existing category. Also update the two documentation files that list known categories:
  - `README.md` — add a row to the rules table and add the category to the "Available categories" line
  - `CLAUDE.md` — add the category to the "Available categories" line in the "Category config" section

In owner mode, `<repo>` is `$CLAUDE_SETUP_PATH`. In contributor mode, `<repo>` is the temp working directory created in Step 6b.

## Step 2 — Write the change

Edit or create the target file. Rule files use this frontmatter format:

```markdown
---
description: <one-line summary — shown in skill/rule pickers>
globs:
  - "**/*.swift"   # adjust to the file types this rule applies to
---

# Rule Title

<content>
```

Write the rule in the same style as existing files in the repo: direct, imperative, code examples where they clarify rather than pad.

## Step 3 — Check coherence

Read every file under `<repo>/rules/` (all categories). For each, check:

- **Duplication**: does the new content repeat something already stated elsewhere?
- **Contradiction**: does the new content conflict with an existing rule?
- **Merge opportunity**: should the new content extend an existing file rather than live in a new one?

If issues are found and the resolution is clear, apply it before proceeding — either by adjusting the new content or updating the conflicting existing file. If the resolution is ambiguous, stop and ask the user how to proceed before making any further changes.

Record findings — they feed the automated section of the PR template in Step 5.

## Step 4 — Show the diff

```bash
git -C <repo> diff
git -C <repo> status
```

## Step 5 — Confirmation gate

Before any commit or PR is opened, present all of the following and wait for explicit user confirmation:

**1. Full diff** (from Step 4)

**2. Filled PR template** — both sections, each item with ✅ or ❌ and a one-line justification or explanation:

*Automated checks* (pre-populated from Step 3 findings):
- No duplication found across existing rules
- No contradiction found across existing rules
- No merge opportunity identified (or: content merged into an existing file instead)

*Author checklist* (evaluated and attested by Claude):
- Frontmatter has a `description` (one line) and `globs` matching the category's file types
- Applies to any project in this category — no internal file paths, type names, or org-specific references
- Not a restatement of Apple/framework documentation — captures a non-obvious constraint, gotcha, or decision
- Non-obvious constraints include a short rationale (the *why*, not just the *what*)
- Complex patterns include a code example

**3. Draft commit message** (owner) or PR title (contributor), following the repo's style (`chore:` or descriptive imperative)

If any item is ❌, surface it explicitly and ask the user how to proceed. Do not silently skip or auto-resolve.

## Step 6a — Owner: commit and push

On confirmation:

```bash
git -C "$CLAUDE_SETUP_PATH" add -A
git -C "$CLAUDE_SETUP_PATH" commit -m "<message>"
git -C "$CLAUDE_SETUP_PATH" push
```

Report success or any errors.

## Step 6b — Contributor: fork, branch, and open PR

On confirmation:

1. **Get GitHub username**:
   ```bash
   GH_USER=$(gh api user --jq '.login')
   ```

2. **Fork the upstream repo** (idempotent — safe to run if a fork already exists):
   ```bash
   gh repo fork artemisia-absynthium/claude-setup
   ```

3. **Clone the fork to a temp directory**:
   ```bash
   WORK_DIR=$(mktemp -d)
   git clone "https://github.com/$GH_USER/claude-setup.git" "$WORK_DIR"
   git -C "$WORK_DIR" remote add upstream https://github.com/artemisia-absynthium/claude-setup.git
   git -C "$WORK_DIR" fetch upstream
   git -C "$WORK_DIR" rebase upstream/main
   ```

4. **Create a branch**:
   ```bash
   BRANCH="add-rule-$(date +%Y%m%d-%H%M%S)"
   git -C "$WORK_DIR" checkout -b "$BRANCH"
   ```

5. **Apply the changes** — write or edit the rule file(s) in `$WORK_DIR` as determined in Steps 1–2. If README.md or CLAUDE.md updates were planned (new category), apply those too.

6. **Commit and push the branch**:
   ```bash
   git -C "$WORK_DIR" add -A
   git -C "$WORK_DIR" commit -m "<message>"
   git -C "$WORK_DIR" push origin "$BRANCH"
   ```

7. **Open the PR**, filling in the template from Step 5:
   ```bash
   gh pr create \
     --repo artemisia-absynthium/claude-setup \
     --head "$GH_USER:$BRANCH" \
     --title "<title>" \
     --body "$(cat <<'EOF'
   ## What this rule covers

   <one sentence>

   ## Automated checks

   - [x] No duplication found — <justification>
   - [x] No contradiction found — <justification>
   - [x] No merge opportunity — <justification>

   ## Author checklist

   - [x] Frontmatter complete
   - [x] Category-general — no org-specific references
   - [x] Captures non-obvious constraint/gotcha
   - [x] Rationale included
   - [x] Code example included (or: not applicable — rule is self-explanatory)
   EOF
   )"
   ```

   Replace `[x]` with `[ ]` for any ❌ items and include the explanation in place of the justification.

8. Report the PR URL to the user.

## What this skill does NOT touch

- Files outside `<repo>/rules/`, `<repo>/skills/`, `<repo>/README.md`, and `<repo>/CLAUDE.md`
- Project-level CLAUDE.md files or `.claude/rules/` directories in any project repo
- The sync workflow (`.github/workflows/sync-claude-rules.yml`) in any subscriber repo
