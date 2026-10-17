---
description: A change to a remote Swift package is developed from its consumer with a local pin that never reaches a commit, tested on both sides and by the owner, and shipped by tag — PR, merge, tag, restore the remote reference, bump
---

# Developing a package change from its consumer

A fix or feature that lives in a remote Swift package but is needed by a consumer — an app or another
package — is developed with the package **pinned locally** and shipped **by tag**. The pin exists so
the consumer can be built and tested before the tag does; it never reaches a commit.

## The pin

First find the dependency's clone; never guess a folder:

- **Known to be cloned, and where** → point at it.
- **Not known** → a brief search of the owner's source tree, or ask the owner; if a clone exists,
  point at it.
- **Not cloned** → clone it into a directory **sibling to the consumer**, never inside the
  consumer's tree (it would clutter the consumer's git status) and never in a session scratchpad
  or worktree (the owner edits and tests there, and the clone outlives the session).

A plain clone is named after the repository, and that is all SwiftPM needs. One case needs care:
when another package in the consumer's graph still pins the dependency by URL, a clone under a
**different** name counts as a second package offering the same targets, and resolution fails with
"multiple similar targets". Then a symlink named like the repository, beside the consumer and
pointing at the clone, resolves it; SwiftPM warns "Conflicting identity … will be escalated to an
error" — that warning is the override working.

```
MyWorkspace/
├── MyConsumer/                  ← the app project, or a package's Package.swift
├── my-package -> MyPackageClone ← symlink, only when the clone was renamed and the graph pins the URL elsewhere
└── MyPackageClone/              ← the clone, on the feature branch
```

The reference takes the consumer's form:

- an **Xcode project** swaps its remote package reference for a local one — keeping the
  reference's UUID so the product dependencies stay attached — with `relativePath` pointing at
  the clone, or at the symlink when one is needed; the workspace `Package.resolved` follows;
- a **package** swaps `.package(url:from:)` for `.package(path: "../my-package")` in its
  `Package.swift`; its `Package.resolved` follows.

The clone is on the feature branch, where the owner edits and tests. The pin is a working-tree edit
of the manifest or project file and of `Package.resolved`; neither is committed, and both are
restored before any commit that touches them.

Other packages in the consumer's graph, and the dependency's own package tests, still resolve the
dependency by URL and tag. Consumer code that uses the new API is therefore buildable and testable
only through the pinned consumer until the tag exists; the rest of the graph's suites run again
after the bump.

## The loop

1. Pin local.
2. Make the changes — in the dependency and in the consumer.
3. Run every test suite on both sides, then the owner's manual test.
4. On the owner's confirmation, open the dependency's PR.
5. PR approved → merge, tag (a release cut the way the dependency's branch model prescribes,
   `workflow/git-discipline.md`), restore the remote reference and `Package.resolved` in the
   consumer, raise the requirement to the new tag (`workflow/version-bumps.md`), and PR the bump.
   PR not approved → repeat from step 2 until it is.

Rationale: a consumer that points at a path, even for one commit in its history, resolves
differently on every machine and in CI; a tag is the only reference every consumer resolves
identically. The pin's whole job is to let the consumer be exercised before that tag exists, and
nothing about it belongs in history. Requirements and the lock file themselves: `xcode/packages.md`.
