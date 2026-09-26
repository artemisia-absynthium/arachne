---
description: Cross-project rule contribution — invoke lift-to-shared-rules when a generalizable pattern is found
---

# Contributing Patterns Upstream

When you identify a coding pattern, constraint, or convention that should apply across all projects — not just the current one — invoke the `lift-to-shared-rules` skill to propose it upstream.

What lifts is a **fact**: an API constraint, a verified platform behaviour, a gotcha with a reproduction. A **process failure** does not lift in the session that produced it. Answering a failure with a rule is the same reflex that produces most failures — elaboration — and a rule written in that moment describes the outcome that was missed, which will be claimed post hoc of anything, rather than the question that would have caught it. Note the failure. If it recurs across sessions, the rule is that question, positioned before the decision it governs, and it replaces a rule rather than joining one.

The lift itself is a proposal — full text shown, nothing written upstream or pushed without an explicit go. The target repository is public; proactive publication was never appropriate there.
