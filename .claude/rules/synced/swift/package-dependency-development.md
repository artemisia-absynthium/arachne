---
description: A change to a remote Swift package is developed from its consumer, pinned to one worktree per dependency branch (named after the repo, never committed), tested on both sides and by the owner, and shipped by tag — PR, merge, tag, remove the worktree, restore the remote reference, bump
---

# Developing a package change from its consumer

A fix or feature that lives in a remote Swift package but is needed by a consumer — an app or another
package — is developed with the package **pinned locally** and shipped **by tag**. The pin exists so
the consumer can be built and tested before the tag does; it never reaches a commit.

## The pin

The consumer is pinned to a **git worktree of the dependency, one per dependency branch in flight** —
never to the dependency's clone itself.

First find the clone; never guess a folder:

- **Known to be cloned, and where** → use it.
- **Not known** → a brief search of the owner's source tree, or ask the owner.
- **Not cloned** → clone it outside every consumer's tree.

The clone is the base: it stays on the default branch or a tag, and nothing is pinned to it or
edited in it. Each branch in flight gets its own worktree
(`git -C <clone> worktree add <path> <branch>`), and the worktree's path follows three rules:

- **Outside every consumer's tree**, which it would otherwise clutter in `git status`.
- **Stable and chosen by the owner**: never a session scratchpad, and never a worktree a session
  creates and cleans up for itself. The owner edits and tests there across review rounds, so the
  worktree outlives any session.
- **The leaf folder is named exactly after the repository**, the last component of its URL.
  SwiftPM identifies a local package by its folder name, and a local package overrides the remote
  dependency "with the same name" (Xcode documentation, *Editing a package dependency as a local
  package*). Under any other name, a graph in which another package still pins the dependency by
  URL fails to resolve with "multiple similar targets". In that graph, with the right name, SwiftPM
  warns "Conflicting identity … will be escalated to an error"; that warning is the override working.

```
MyWorkspace/
├── MyApp/                         ← consumer, pinned to worktrees/fix-cache/my-package
├── MyOtherApp/                    ← consumer, pinned to worktrees/new-api/my-package
├── my-package/                    ← the clone: default branch, never pinned
└── worktrees/
    ├── fix-cache/my-package/      ← worktree on fix/cache
    └── new-api/my-package/        ← worktree on feature/new-api
```

Every consumer that tests a branch pins that branch's worktree, so two consumers testing the same
branch share one checkout and build the same code.

Rationale: a dependency serves several consumers, and with two of its branches in flight a single
checkout can hold only one of them. A consumer then builds whichever branch the last checkout left
behind. Git refuses to check out a branch that another worktree already has (`git-worktree(1)`),
so each branch has exactly one place, and the pin names that place.

The reference takes the consumer's form:

- an **Xcode project** swaps its remote package reference for a local one — keeping the
  reference's UUID so the product dependencies stay attached — with `relativePath` pointing at
  the worktree; the workspace `Package.resolved` follows;
- a **package** swaps `.package(url:from:)` for
  `.package(path: "../worktrees/fix-cache/my-package")` in its `Package.swift`; its
  `Package.resolved` follows.

The pin is a working-tree edit of the manifest or project file and of `Package.resolved`; neither
is committed, and both are restored before any commit that touches them.

Other packages in the consumer's graph, and the dependency's own package tests, still resolve the
dependency by URL and tag. Consumer code that uses the new API is therefore buildable and testable
only through the pinned consumer until the tag exists; the rest of the graph's suites run again
after the bump.

## The loop

1. Add the branch's worktree and pin the consumer to it.
2. Make the changes — in the dependency's worktree and in the consumer.
3. Run every test suite on both sides, then the owner's manual test.
4. On the owner's confirmation, open the dependency's PR.
5. PR approved → merge, tag (a release cut the way the dependency's branch model prescribes,
   `workflow/git-discipline.md`), remove the worktree (`git worktree remove`) in the same step
   that deletes the merged branch, restore the remote reference and `Package.resolved` in every
   consumer pinned to it, raise the requirement to the new tag (`workflow/version-bumps.md`), and
   PR the bump. PR not approved → repeat from step 2 until it is.

Rationale: a consumer that points at a path, even for one commit in its history, resolves
differently on every machine and in CI; a tag is the only reference every consumer resolves
identically. The pin's whole job is to let the consumer be exercised before that tag exists, and
nothing about it belongs in history. Requirements and the lock file themselves: `xcode/packages.md`.
