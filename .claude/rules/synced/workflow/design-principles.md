---
description: Uncle Bob's SOLID — type-level single-responsibility enforced at plan time and via an implementation tripwire, not discovered in post-hoc review
paths:
  - "**/*"
---

# Design Principles — Uncle Bob's SOLID From the Start

Apply Robert C. Martin's ("Uncle Bob") SOLID principles — above all the Single
Responsibility Principle in its original form: a type should have one reason to change,
one actor it answers to. Type-level design is enforced during planning and implementation,
not discovered in review.
A post-hoc design review that fails is a plan that failed earlier: by then the refactor is
too large to fold into the same change and gets postponed, and postponed refactors compound.

## At plan time

- For every type the plan touches, state which responsibilities it gains. A type gaining a
  responsibility outside the contract its name states ⇒ the plan includes the extraction as
  part of the same work item — never "as a follow-up".
- New state added to an existing type must name its lifetime (who resets it, when). Two
  different lifetimes living in one type is a split signal.

## While implementing — the tripwire

Stop and propose a split immediately (mid-task, not at review time) when a type being edited:

- exceeds ~300 lines, or
- exceeds ~15 stored properties, or
- holds state with two different lifetimes, or
- gains a responsibility its name doesn't cover.

Proposing the split is mandatory; deferring it is the user's call, never a silent default.
The rationale: god classes are never designed — they accrete through individually reasonable
increments, and only a per-increment check catches the accretion while the fix is still small.

## Tiebreak vs "no premature abstraction"

Rules like "don't introduce an abstraction until it has two users" govern protocols,
generics, and indirection layers. They do NOT apply to extracting concrete collaborator
types out of a growing class: owned concrete types with one implementation and no protocol
are the cure for a god class, not premature abstraction. When single-responsibility and
"simplest shape" pull in opposite directions at the type level, single-responsibility wins.

## Design review lens

The comprehensive review checklist (SOLID, Clean Architecture, GRASP, Clean Code,
coupling laws, guardrails) lives in the `design-review-lens` skill — invoke it for the
design pass of the PR gate or any standalone design review. This file keeps only what
must be active while planning and writing code.
