---
description: No commit introduces a warning or a lint violation — pre-existing ones are fixed in their own commit before the requested work starts, as priced side-work, and a suppression carries the reason the fix would be worse
---

# Warning Discipline

The project builds with **zero warnings** and lints clean: no commit introduces a warning or a
violation, and pre-existing ones are removed in changes of their own. The policy is the same
whatever the compiler or linter; the suppression syntax each tool takes is the stack's own
instruction file.

## Zero warnings

- **Before starting any task**: check for existing warnings and report them. Fix them — in the
  sense of `terminology.md`: cause named, remedy prescribed, effect verified — in a separate,
  independent commit before touching the requested work. That fix is side-work in the sense of
  `side-work.md`: priced when admitted, and left to a dedicated change when the price is exceeded.
- **Never commit code that introduces a new warning.** A commit that adds none is the
  pre-condition for every commit, not a post-task cleanup step.
- **After a toolchain upgrade**, new compiler or linter diagnostics are treated as bugs. Fix them
  before any other work and land them in their own commit, so the cleanup is isolated from
  feature changes — the same side-work, with the same price.

## Suppression

Fix lint violations. Suppress only when the violation is a false positive or the correct fix
would produce materially worse code.

- **Never silence a rule project-wide** in the linter's configuration. A global disable hides
  real issues across the whole codebase and cannot be undone safely without auditing every
  affected site.
- **Narrowest scope.** A suppression covers one line, or one block re-enabled immediately after
  it — never a file, never a module.
- **Every suppression carries its reason**, immediately above it: *why the fix would be worse
  than the suppression*, not what is being suppressed. A bare suppression with no rationale is
  rejected in code review.
- Before suppressing, ask whether the code can be restructured so the violation disappears.

Rationale: a warning is the toolchain's cheapest bug report, and a codebase that tolerates some
teaches every reader to skim past all of them — the one that matters is then indistinguishable
from the noise. A suppression without a reason is a warning that was hidden instead of read.
