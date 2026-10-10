---
name: code-simplifier
description: Simplify the code a task just changed, for clarity and consistency, without changing what it does — against the project's own code-style rules where it has them, otherwise established simplification practice. Runs as a delegated fix batch after verification and before the review pass, on the diff only. Invoke when asked to simplify, clean up, or refine code just written.
---

# Code simplifier

A brief for a delegated pass over the task's diff. The pass changes how the code does what
it does, never what it does: every feature, output and observable behaviour stays, and the
project's verification (build, tests with their executed count, lint, zero warnings) is green
after the pass as it was before. The pass runs once the task's own verification is green and
before the review pass, so the reviewers certify the simplified code and no delta review is
needed for the simplification itself.

## What governs the rewrite, in this order

1. **The project's own rules.** Its code-style and convention files (the instruction files it
   loads, the synced stack rules) decide naming, layout, imports, error handling and idiom.
   Where the project states a convention, apply it; where surrounding code violates it, the new
   code still follows it and the neighbour is left as it is (`code-style.md`).
2. **The stack's established practice** where the project is silent: the language's idioms as
   its own style guide states them.
3. **General simplification practice** where both are silent, which is Clean Code hygiene:
   names that state purpose, not mechanism; functions at one level of abstraction, read in
   step-down order; no side effects behind innocent names; one piece of knowledge in one place;
   flat control flow — guard clauses over nesting, a `switch` or an `if` chain over a nested
   conditional expression; related logic consolidated; comments that restate the code deleted,
   comments that carry a reason kept.

## What the pass does not do

- It does not remove an abstraction that carries a decision, merge concerns into one unit, or
  trade debuggability for fewer lines: explicit code beats a dense one-liner, and a change that
  a reader would need the old version to understand is not a simplification.
- It does not touch code outside the diff. A pre-existing smell next to the change is an
  observation in the report, never an edit (`side-work.md`: unpriced side-work is how a small
  task rewrites what it never needed to touch).
- It does not alter a wire contract, a public signature, a persisted format, or a test's
  assertion. A test that must change to stay green after the pass means the pass changed
  behaviour: revert that change.
- It does not add. Every change in its report deletes, flattens, renames or consolidates.

## Return

A list of the changes made, each as `path: what changed — the rule or practice it applies`,
then the observations outside the diff, then the verification verdicts after the pass (the
same checks the task ran, with the same results). Nothing else: no prose summary, no restated
diff. An empty list is a valid result when the diff is already as simple as it should be.
