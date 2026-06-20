---
description: Cross-language code style rules that apply regardless of stack
paths:
  - "**/*"
---

# Code Style

## Comments

Default to no comments. Add one only when the WHY is non-obvious: a hidden constraint, a subtle invariant, a bug workaround, or behaviour that would surprise a future reader. Never explain WHAT the code does — well-named identifiers do that.

Single-line comments are preferred. Multi-line is allowed only when the WHY is genuinely too complex for one line — a subtle invariant spanning multiple interacting systems, or a workaround that needs context to be understood without the commit history. Do not use multiple lines to explain WHAT.

## Pre-existing violations

When surrounding code violates a project convention, new code must still follow the rule — never mirror a violation because the neighbors do it. Stop the bleeding; don't match bad neighbors.

Pre-existing violations get annotated with a `TECH-DEBT` comment so they can be tracked and migrated incrementally, one file at a time. Do not fix them all in a sweep as part of unrelated work — that produces noisy diffs and risks regressions.

```
// TECH-DEBT: migrate to <correct pattern> — inherited from before the convention was established
<pre-existing violation left as-is>
```

Debt acknowledged, not compounded.

## Comments examples

```
// ✅ — one line; explains a non-obvious constraint
// Gate is checked after flush, not before, to avoid a TOCTOU race.
if not conditionMet: return

// ✅ — multi-line because the invariant spans two interacting subsystems and
// one line would be too terse to be useful without the surrounding context
// SubsystemA drives the shared limit; SubsystemB must read the negotiated value
// after SubsystemA commits it, or it may enforce a stale local cap.
function initialize() { ... }

// ❌ — explains WHAT; the function name already says this
// Parses the message and returns the limit and flag.
function parseMessage(data) { ... }
```
