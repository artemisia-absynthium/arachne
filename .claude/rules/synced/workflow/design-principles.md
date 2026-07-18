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

## Design review lens (pre-PR gate, pass 1)

The comprehensive checklist for the design pass. Every item is a question about the diff,
not a definition.

**SOLID (Robert C. Martin, "Uncle Bob")**

- **SRP** — one reason to change, one actor per type; the tripwire thresholds above apply.
- **OCP** — is new behavior added via new types/cases, or by editing every existing
  `switch`? A diff that touches N sites to add one concept is a finding (shotgun surgery).
- **LSP** — do subtypes and protocol conformances honor the full contract? Strengthened
  preconditions, weakened guarantees, or "not supported" stubs are findings.
- **ISP** — is any consumer forced to depend on members it never calls? Fat protocols
  split along client lines.
- **DIP** — does high-level policy import low-level detail? Dependencies point at
  abstractions the *consumer* owns; a library stays consumer-agnostic.

**Clean Architecture (Uncle Bob) — boundaries**

- Source dependencies point inward: domain ← application ← infrastructure/UI. Framework
  types don't leak across a boundary; boundaries cross with plain data.

**GRASP (Craig Larman)**

- **Information Expert** — does behavior live with the data it needs? A method
  interrogating another object's state to decide belongs on that object.
- **Creator** — are instances created by the type that owns/aggregates them, not by a
  bystander?
- **Low Coupling / High Cohesion** — the summary judgment on every *new dependency edge*
  the diff introduces: does it pay for itself?
- **Controller** — do entry points (views, handlers, delegates) only delegate? Business
  rules in UI or transport code are findings.
- **Polymorphism** — is anything switching on a type/kind tag that should be polymorphic
  dispatch?
- **Pure Fabrication** — when no domain concept fits, inventing a coordinator/policy type
  is correct — this is the license behind collaborator extraction.
- **Protected Variations / Indirection** — are *identified* variation points (not
  speculative ones) behind a stable seam?

**Clean Code hygiene (Uncle Bob)**

- Intention-revealing names — a name states purpose, never mechanism.
- Small functions, one abstraction level each; reading order follows the step-down rule.
- **CQS** — a function either answers a question or mutates state, never both.
- No side effects hiding behind innocent names.
- **DRY, with the Metz caveat** — duplicated *knowledge* is a finding; duplicated *code*
  is cheaper than the wrong abstraction.

**Coupling laws**

- **Law of Demeter** — talk to friends, not strangers: `a.b().c()` chains reaching
  through objects are findings.
- **Tell, Don't Ask** — fetching state, deciding, and writing back is the owner's
  decision leaked outward.
- **Composition over inheritance** — a subclass wanting only part of its parent is
  composition waiting to happen.

**Guardrails — what NOT to flag**

- YAGNI/KISS still govern: single-use protocols, speculative generics, and indirection
  without an identified variation are findings *in the other direction*. The tiebreak
  above stands: concrete collaborator extraction from a god class is never
  over-engineering.
- Principle of least astonishment: surprising behavior behind a conventional-looking API
  is a finding even when technically correct.
