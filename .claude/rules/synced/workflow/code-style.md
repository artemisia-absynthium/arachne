---
description: Cross-language code style — pre-existing violations are annotated as TECH-DEBT, never mirrored
paths:
  - "**/*"
---

# Code Style

## Pre-existing violations

When surrounding code violates a project convention, new code must still follow the rule — never mirror a violation because the neighbors do it. Stop the bleeding; don't match bad neighbors.

Pre-existing violations get annotated with a `TECH-DEBT` comment so they can be tracked and migrated incrementally, one file at a time. Do not fix them all in a sweep as part of unrelated work — that produces noisy diffs and risks regressions.

```
// TECH-DEBT: migrate to <correct pattern> — inherited from before the convention was established
<pre-existing violation left as-is>
```

Debt acknowledged, not compounded.
