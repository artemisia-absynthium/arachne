---
description: The branch model is read from the repo's config, never assumed; fetch before starting on a shared branch and before every rebase; push once when the changeset is final; rewrites gated by branch kind; on GitHub, PRs that build on each other are linked into a stack when opened and merge from the top; a merged branch is deleted in the same step; docs-only diffs skip the PR
---

# Git discipline

## The branch model is read, never assumed

Read the repo's branching model from its configuration — `git config --get-regexp '^gitflow'`
where git-flow is used, the remote's HEAD for the default branch otherwise — before the first
branch, merge or rebase. A repo's names and prefixes are its own; a guessed `main` or `develop`
lands work on the wrong branch.

## Push once, when the changeset is final

An unpushed commit is freely editable (squash, reword, drop); a pushed one is shared history.
Pushing eagerly converts trivial local history editing into force-push requests that protected
branches refuse. Commit locally as work progresses; push once, when the changeset is final and
the owner says so. A step that needs the remote — PR creation, a remote CI job — is where the
workflow waits for that word, not an authorization in itself: green builds and passing suites
cannot see rendered UI or real behaviour, so the owner's own check is the last verification
before anything leaves the machine. Review rounds are
local: fix, re-run locally; on a clean re-run, squash the round-fix commits, then push once and
open the PR on the owner's word — pushing per round litters the remote branch history. Once a
PR is open, a received review is answered through `respond-to-pr-review`: the owner reads the
replies before anything is posted, and the round's push waits for their word like any other.

## Fetch before starting on a shared branch, and before every rebase

On a shared branch — the git-flow mainline branches, read from `git config --get-regexp
'^gitflow\.branch'` — bring it up to date before the first edit when the last fetch is older
than about an hour: `git fetch origin <base> && git merge --ff-only FETCH_HEAD` (the explicit form
works on a dirty tree when the incoming files are disjoint; `git pull --ff-only` refuses under
`pull.rebase`). A solo topic branch is refreshed by an explicit rebase when the author chooses,
never by an ambient pull. A rebase fetches first, every time, and rebases onto the
remote-tracking ref — `git fetch origin <base> && git rebase origin/<base>` — never onto the local
base, which can sit behind `origin/<base>` even right after a fetch.

## History rewrites are gated by branch kind, not banned

- **Solo topic branches** — rebase onto the updated base and force-push freely, with
  `--force-with-lease` (it aborts if the remote moved unexpectedly). One author, no one to
  strand.
- **Shared and long-lived branches** — the integration branch, the mainline, release branches,
  anything several people or CI track — are never rewritten or force-pushed. A clean mainline
  narrative comes from a squash or curated merge at PR time. A rewrite that cannot be done with
  certainty of breaking nothing is skipped.

## On GitHub, pull requests that build on each other are a stack

This section applies only where the remote's host is GitHub (`git remote get-url origin`); other
hosts have their own stacking, or none, and keep their own conventions. There, when pull requests
build on each other — each one's base is the branch of the one below it — they are linked into a
GitHub stack as they are opened, never left as a chain of bases for someone to stack by hand. Each PR is opened as usual, then `gh stack link <bottom> … <top>` (PR numbers,
bottom to top; the `github/gh-stack` extension) runs under the same go as opening them; a PR opened
later on top is appended the same way. Two consequences change how the stack is planned:

- Every PR in a stack is judged by the rules of the **stack's base** — typically the integration
  branch — whatever branch it directly targets: each needs the approvals that base requires, and
  merge requirements cannot be bypassed.
- A stack merges **from the top**: merging a PR merges every PR below it in one all-or-nothing
  operation (`gh stack merge <pr>`). It is never planned as bottom-up merges one at a time.

**Why:** a long chain of PRs was opened one by one against each other's branches. A person had to
stack it by hand; linking put every PR under the integration branch's review rule at once, so they
read "review required" again; and a bottom-up merge was proposed for a stack that merges only from
the top. Source: GitHub Docs, "About stacked pull requests" and the stacked pull requests reference.

## Finishing a branch: the merge and the delete are one step

A topic branch the assistant merges — into the integration branch, the integration branch into
the mainline, a hotfix into both — is deleted in the same step: the local branch always, the
remote one too when it was pushed and the merge is pushed. Stopping at the merge is not
finishing: a merged branch holds no information the merge commit does not. Branches the
assistant did not merge are not its to delete.

**Why (owner correction):** a bugfix branch merged into the integration branch, and that into
the mainline, was left in the repo — "you are leaving junk after yourself".

## Docs-only diffs skip the PR ceremony

A diff touching only documentation commits straight to the default branch: reviews exist for
code, and documentation records are low-risk, so the ceremony is pure overhead. Anything
code-bearing goes through the PR route.
