---
description: A passing build is part of Definition of Done — blockers requiring human action are flagged, never worked around
paths:
  - "**/*"
---

# Build Discipline

A passing build is a mandatory verification step and part of the Definition of Done for every task — a build error is in scope regardless of whether the current task introduced it. Fix it first, in a separate commit if needed, then continue.

## When human intervention is required

Some build failures require the developer to act — for example: missing generated assets, missing credentials, or hardware-specific setup that cannot be automated. In those cases:

- Flag the blocker to the user explicitly: name the file, the missing asset, or the setup step required.
- Do **not** proceed past the verification step and claim the task is done.
- Do **not** suppress or work around the error to make the build pass artificially.

The pattern is: *"Build fails with X — this requires [specific human action] before I can verify. Once resolved, I'll confirm the build passes."*

## Relationship to warnings

This rule is about build errors (compilation failures). See the Xcode warning discipline rule for zero-warnings policy, which is a complementary but separate constraint.
