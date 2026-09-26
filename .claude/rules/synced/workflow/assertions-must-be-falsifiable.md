---
description: Every assertion, invariant check and "this test catches X" claim must be able to fail — name the single production mutation that turns it red before committing it
---

# Assertions Must Be Falsifiable

Before committing a test, name the **single change to production code** that turns it red.
If you cannot, the assertion is decoration — and decoration is worse than absence: a missing
test is visible in coverage, while an assertion that cannot fail is counted, reviewed and
trusted, and it occupies the slot where the real check would go. This is the assertion-level
form of the charter's rule that "must stay true" lines are answered with evidence, never
asserted (`charter.md`).

## Shapes that cannot fail

- **Asserting a default.** `expect(model.progress == 0)` right after construction, where `0`
  is the initializer's value — true whether or not the code under test ran. The design-time
  form is the planning skill's *lying fixture*.
- **Restating the selector.** An invariant helper that checks
  `pending.contains(id) || owners[id] != nil` after `state(for:)` returned `.pending` — it
  re-derives the `switch` that produced the state and can only agree with it.
- **A tautological oracle.** A property test whose expected value is computed with the
  implementation's own arithmetic. The oracle must come from the generator's *construction*
  (it planted the answer) or from an independent definition, never from re-running the rule
  under test.
- **Boundary claimed, boundary excluded.** A generator built to keep every value away from
  the exact threshold, beside a comment saying the test distinguishes `>` from `>=`.
- **A mutation named but not killed.** A doc comment saying "fails if the guard is removed"
  is a claim about the test. Apply the mutation once and confirm red before writing the
  sentence.

## Comments are not tests

When a seam exists to pin an invariant with a test, write the test. A comment that says
"deliberately not symmetrical with X" enforces nothing: the cleanup that makes it symmetrical
passes green. This does not reach justifications the compiler or a linter demands — a warning
suppression (`xcode/warnings.md`), a concurrency guarantee (`swift/concurrency.md`): those have
no seam and stay comments.

## Framework behaviour is a fact, not a rationale

A suite header saying "serialized, so tests in this file cannot race the sibling suite" is a
factual claim about the test framework (the Swift instance is in `swift/testing.md`). Verify
it against an authoritative source (`terminology.md`) before writing it — a false rationale
in a header is worse than none, because it tells the next author the protection is already
in place.

## Run the negative control before you call it done

Having written the test, revert the fix (or apply the mutation you named), run, and see red.
This is the author's check, done at write time: a green run proves the test passes, not that
it can fail.
