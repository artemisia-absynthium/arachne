---
description: A passing build is part of Definition of Done — blockers requiring human action are flagged, never worked around
---

# Build Discipline

A passing build is a mandatory verification step and part of the Definition of Done for every task — a build error is in scope regardless of whether the current task introduced it. It is *fixed* in the sense of `terminology.md`: cause named from an authoritative source, remedy the prescribed one, effect verified — in its own commit when separable. A change that makes the error stop appearing without a named cause is a workaround: proposed, not applied. "Cannot be fixed correctly" is reported as a blocker, never worked around.

## When human intervention is required

Some build failures require the developer to act — for example: missing generated assets, missing credentials, or hardware-specific setup that cannot be automated. In those cases:

- Flag the blocker to the user explicitly: name the file, the missing asset, or the setup step required.
- Do **not** proceed past the verification step and claim the task is done.
- Do **not** suppress or work around the error to make the build pass artificially.

The pattern is: *"Build fails with X — this requires [specific human action] before I can verify. Once resolved, I'll confirm the build passes."*

## Relationship to warnings

This rule is about build errors (compilation failures). See the Xcode warning discipline rule for zero-warnings policy, which is a complementary but separate constraint.
