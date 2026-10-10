---
description: The branch model is read from the repo's config, never assumed; push once when the changeset is final; rewrites gated by branch kind; a merged branch is deleted in the same step; docs-only diffs skip the PR
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
before anything leaves the machine. Never chain commit and push by default. Review rounds are
local: fix, re-run locally; on a clean re-run, squash the round-fix commits, then push once and
open the PR on the owner's word — pushing per round litters the remote branch history. Once a
PR is open, a received review is answered through `respond-to-pr-review`: the owner's approval
of its response draft is the word for that round's push, given in advance for exactly that draft
and void on any divergence, and in that draft the owner decides per remedy which ones their own
check must see before the push.

## History rewrites are gated by branch kind, not banned

- **Solo topic branches** — rebase onto the updated base and force-push freely, with
  `--force-with-lease` (it aborts if the remote moved unexpectedly). One author, no one to
  strand.
- **Shared and long-lived branches** — the integration branch, the mainline, release branches,
  anything several people or CI track — are never rewritten or force-pushed. A clean mainline
  narrative comes from a squash or curated merge at PR time. A rewrite that cannot be done with
  certainty of breaking nothing is skipped.
- Interactive rebase is unavailable in this environment; a plain `git rebase <base>` is the
  tool.

## Finishing a branch: the merge and the delete are one step

A topic branch the assistant merges — into the integration branch, the integration branch into
the mainline, a hotfix into both — is deleted in the same step: the local branch always, the
remote one too when it was pushed and the merge is pushed. Stopping at the merge is not
finishing: a merged branch holds no information the merge commit does not. Branches the
assistant did not merge are not its to delete.

**Why (owner correction):** a bugfix branch merged into the integration branch, and that into
the mainline, was left in the repo — "you are leaving junk after yourself".

## Docs-only diffs skip the PR ceremony

A diff touching only documentation commits straight to the default branch (`change-tiers.md`,
T0): the review passes exist for code, and documentation records are low-risk, so the ceremony
is pure overhead. Anything code-bearing goes through the PR route and the review gates.
