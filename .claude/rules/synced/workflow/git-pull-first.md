---
description: On a shared branch (main/develop), fetch + fast-forward before the first edit when the last fetch is older than an hour — never on solo feature branches, never on every commit; before any rebase, fetch the base and rebase onto its remote-tracking ref
paths:
  - "**/*"
---

# Pull First — on shared branches when stale, and before every rebase

Before the first edit of a task **on a shared branch** — the git-flow mainline branches, read
from `git config --get-regexp '^gitflow\.branch'` (typically `main`/`master` and `develop`) —
bring it up to date when the last fetch is older than about an hour:

```sh
[ -z "$(find .git/FETCH_HEAD -mmin -60 2>/dev/null)" ] && git fetch origin <base> && git merge --ff-only FETCH_HEAD
```

`merge --ff-only FETCH_HEAD` works on a dirty tree when the incoming files are disjoint;
`git pull --ff-only` refuses under `pull.rebase` when the tree is dirty, so prefer the explicit form.

Scope, deliberately narrow:

- **Shared branches only.** A solo `feature/`, `bugfix/`, `release/` or `hotfix/` branch has no
  one else committing to it; its base is refreshed by an explicit rebase when the author chooses,
  not by an ambient pull.
- **Staleness-gated, not per-commit.** Fetching before every commit in a session that started
  current is noise. The gate is the age of the last fetch, not the age of the head commit — a head
  can be legitimately days old on a quiet branch while a fetch minutes ago proved it current.

Rationale: on a shared branch, a stale base means edits against files someone else has already
changed, conflicts found at commit time instead of at the start, and pointers written to content
that has already moved. All of those are cheaper to find before the first edit than after the last.

## Before a rebase, fetch the base — every time

The one case with no staleness gate: a rebase exists to put the branch on the base's *current*
head, so it fetches first, unconditionally, and rebases onto the **remote-tracking ref**, never
onto the local base branch:

```sh
git fetch origin <base> && git rebase origin/<base>
```

The local `develop` is a snapshot from whenever it was last fast-forwarded; even right after a
fetch it can sit behind `origin/develop` if nobody merged the fetch into it. Rebasing onto it
produces a branch that is "rebased" yet already stale — the author discovers this at push or
merge time and has to rebase again, conflicts included, minutes later.

Rationale: a rebase onto a stale head has all of the cost of a rebase and none of the benefit;
the fetch is cheap, the second rebase is not.
