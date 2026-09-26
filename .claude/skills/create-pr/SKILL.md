---
name: create-pr
description: Create a GitHub pull request from the current branch — base detected from the remote, assignee the authenticated user, reviewer asked for and remembered per project, body filled from the repo's PR template or a conventional default, describing the result against the base. Invoke when asked to create a PR, open a pull request, or submit changes for review.
---

# create-pr

## Rules

- The assignee is the currently authenticated `gh` user.
- The PR is created from the **current branch** of the repo the user is working in.
- Opening the PR is the publish step: the request to open it covers the push of the branch.

## 0. Verify `gh` authentication

```bash
gh auth status
```

If `gh` is signed out, stop and ask the user to run `gh auth login` in a terminal tab, then retry.

## 1. Get the current GitHub user

```bash
gh api user --jq '.login'
```

This is the assignee.

## 2. Detect the base branch

```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
```

If the remote HEAD is unset, fall back to `develop`, then `main`, then `master`:

```bash
git branch -r | grep -E 'origin/(develop|main|master)' | head -1 | sed 's@.*origin/@@'
```

Use the result as `<base>` below.

## 3. Push if needed

```bash
git status
```

If the branch lacks an upstream or is ahead of it:

```bash
git push -u origin HEAD
```

## 4. Gather the material

```bash
git log origin/<base>..HEAD --format='%s%n%n%b'
git diff origin/<base>...HEAD --stat
```

Subjects and bodies only: they are the material the description is written from, and they
survive a rebase.

## 5. Ask about the reviewer

- Check memory for a reviewer previously remembered for this project.
- If one exists: ask "Should I add **{reviewer}** as reviewer again, or someone different?"
- Otherwise ask "Who should I add as reviewer? (GitHub username)"
- Save the answer to memory so it persists across sessions.

## 6. Write the description

The description describes the change **from the base to the head**, the way the merge commit
would.

Look for a pull request template where GitHub does: the repository root, `docs/`, or
`.github/`, named `pull_request_template` in any letter case, with a `.md` or `.txt` extension.

```bash
find . docs .github -maxdepth 1 -iname 'pull_request_template.*' 2>/dev/null
```

- **Found:** it is the structure. Fill in whatever it asks for, each part when there is
  something real to put in it; keep the parts that apply and remove the rest. If it asks for
  screenshots, they belong only when the change is visual — a view, a layout, a style — and
  the tooling offers a capture (a device or simulator); in every other case skip the section.
- **Otherwise** use this conventional structure:

  ```markdown
  ## Summary
  <!-- what changed and why, 2–4 sentences -->

  ## Changes
  <!-- the result against the base, grouped by concern -->

  ## Testing
  <!-- how it was verified, and how a reviewer can repeat it -->

  ## Related
  <!-- issues, tickets, follow-ups -->
  ```

## 7. Create the PR

```bash
gh pr create \
  --base <base> \
  --title "<concise title, under 70 chars>" \
  --assignee <user from step 1> \
  --reviewer <reviewer from step 5> \
  --body "$(cat <<'BODY'
<filled template>
BODY
)"
```

## 8. Return the PR URL to the user
