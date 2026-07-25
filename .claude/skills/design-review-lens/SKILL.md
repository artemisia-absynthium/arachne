---
name: design-review-lens
description: The full design-review checklist (SOLID, Clean Architecture boundaries, GRASP, Clean Code hygiene, coupling laws, anti-over-engineering guardrails) for reviewing a diff or branch. Invoke for the design pass of the pr-review-gate, or whenever performing a design, SOLID, or architecture review of code changes.
---

# Design Review Lens

The comprehensive checklist for a design review pass. Every item is a question about the
diff, not a definition. Type-level thresholds that count as automatic findings: a type
exceeding ~300 lines or ~15 stored properties, holding state with two different
lifetimes, or gaining a responsibility its name doesn't cover.

**SOLID (Robert C. Martin, "Uncle Bob")**

- **SRP** — one reason to change, one actor per type; the thresholds above apply.
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
  without an identified variation are findings *in the other direction*. Concrete
  collaborator extraction from a god class is never over-engineering.
- Principle of least astonishment: surprising behavior behind a conventional-looking API
  is a finding even when technically correct.
