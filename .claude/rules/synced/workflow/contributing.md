---
description: What lifts upstream is a fact, never a process failure in the session that produced it
---

# Contributing Patterns Upstream

What lifts upstream (`lift-to-shared-rules`) is a **fact**: an API constraint, a verified platform behaviour, a gotcha with a reproduction. A **process failure** does not lift in the session that produced it. Answering a failure with a rule is the same reflex that produces most failures — elaboration — and a rule written in that moment describes the outcome that was missed, which will be claimed post hoc of anything, rather than the question that would have caught it. Note the failure. If it recurs across sessions, the rule is that question, positioned before the decision it governs, and it replaces a rule rather than joining one.
