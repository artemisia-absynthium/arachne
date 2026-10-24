---
description: No commit introduces a warning or a lint violation in the code it touches; pre-existing warnings elsewhere are reported, never swept; a suppression carries the reason the fix would be worse
---

# Warning Discipline

The code a commit touches builds with **zero warnings** and lints clean. The policy is the same
whatever the compiler or linter; the suppression syntax each tool takes is the stack's own
instruction file.

## Zero warnings in touched code

- **Never commit code that introduces a warning.** A new warning on a line the change wrote or
  touched is fixed before the commit — in the sense of `terminology.md`: cause named, remedy
  prescribed, effect verified. A commit that adds none is the pre-condition for every commit, not
  a post-task cleanup step.
- **Pre-existing warnings in untouched code are not this task's.** They are reported once and
  left where they are; fixing them is a change of its own, when the owner asks for it.
- **After a toolchain upgrade**, new compiler or linter diagnostics in touched code are treated
  as bugs.

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
