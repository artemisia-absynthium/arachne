---
description: Cross-language code style — pre-existing violations are annotated as TECH-DEBT, never mirrored
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

## Scope: style, not design

This rule governs *style and convention* — naming, formatting, logging, file layout. It
does not make existing *design* a baseline to preserve. Reluctance to touch what is not
in the way is good practice; treating an existing structure as a requirement because it
exists is not. When keeping a structure starts costing a mechanism, the structure has to
justify itself, and that judgment is `planning-discipline`, question 2.
