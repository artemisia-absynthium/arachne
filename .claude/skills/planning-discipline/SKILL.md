---
name: planning-discipline
description: Type-level design (SOLID/SRP), invariant-first planning, named precedents, and complexity budgets. Invoke while planning or designing any non-trivial feature — mandatory for stateful mechanisms (state machines, caches, sync/retry, lifecycles) — and when reviewing a design note before code exists.
---

# Planning discipline — type-level design + invariant-first

Two disciplines, applied together at plan time. Type-level design says who owns what;
invariant-first says what must stay true and who enforces it. Neither substitutes for the
other. A post-hoc design review that fails is a plan that failed earlier: by then the
refactor is too large to fold into the same change and gets postponed, and postponed
refactors compound.

## Type-level design (SOLID from the start)

Apply the Single Responsibility Principle in its original form: a type has one reason to
change, one actor it answers to. Enforced during planning and implementation, not
discovered in review.

**At plan time:**
- For every type the plan touches, state which responsibilities it gains. A type gaining a
  responsibility outside the contract its name states ⇒ the plan includes the extraction as
  part of the same work item — never "as a follow-up".
- New state added to an existing type must name its lifetime (who resets it, when). Two
  different lifetimes living in one type is a split signal.

**While implementing — the tripwire.** Stop and propose a split immediately (mid-task, not
at review time) when a type being edited: exceeds ~300 lines, or ~15 stored properties, or
holds state with two different lifetimes, or gains a responsibility its name doesn't cover.
Proposing the split is mandatory; deferring it is the user's call, never a silent default.
God classes are never designed — they accrete through individually reasonable increments,
and only a per-increment check catches the accretion while the fix is still small.

**Tiebreak vs "no premature abstraction".** Rules like "don't introduce an abstraction
until it has two users" govern protocols, generics, and indirection layers. They do NOT
apply to extracting concrete collaborator types out of a growing class: owned concrete
types with one implementation and no protocol are the cure for a god class, not premature
abstraction. When single-responsibility and "simplest shape" pull in opposite directions at
the type level, single-responsibility wins.

## Solutions are rooted in the literature

Treat every design problem as an instance of a known problem until shown otherwise: name
the precedent — design pattern, algorithm, data structure, architectural style, concurrency
primitive — and take its known solution, adapted, stating what was adapted and why. A
mechanism with no named precedent is presumed invented, and invention requires
justification: what was searched, and why nothing fits. Novelty is a cost — an invented
mechanism has no literature documenting its failure modes.

Calibration: the demand is the *mapping*, not the ceremony. "This is a plain loop / a
switch over a closed set — no precedent needed" is a valid mapping for trivial mechanism;
forcing a Visitor where a switch is proportionate is the inverse failure. The rule bites on
non-trivial mechanism — state machines, caches, schedulers, synchronization, retry/backoff,
parsers, distributed or exactly-once semantics.

**In-house literature first.** An in-house package is an SDK: the documentation-retrieval
step that already covers platform and third-party APIs covers it identically. Each package
carries its own documentation — its `CLAUDE.md`, `README.md`, and source tree as the
component index — and reading it is part of planning, not an optional extra; the consuming
project's docs will not (and need not) point there. Before designing ANY mechanism (UI
component, paging behaviour, cache, formatter, …), read the in-house packages' docs and grep
them by capability. A package consumed as a remote dependency is read at its repository or in
a throwaway clone outside the project — never from the build system's checkout (DerivedData
`SourcePackages/checkouts`, `.build/checkouts/`), a disposable working copy that has already
produced a refuted review finding. "Nothing in-house fits" is valid only with the consulted
packages listed. Why: a paging component in a module the edited file already imported, named
in that package's own CLAUDE.md, went unfound while two bespoke paging mechanisms were built
and review-cycled for ~4 rounds — the platform literature had been searched, the in-house
SDK's documentation never opened.

## Complexity is stated at plan time

For every operation over a collection, stream, or query, the plan names the expected input
scale and the time/space complexity of the chosen approach. "n is small and bounded" is a
valid answer — but it must be *said*, with the bound, so the assumption is visible the day
the bound changes.

## Shipped vs unshipped — compat ceremony only for fielded contracts

Before proposing any backwards-compatibility or migration-safety machinery, determine whether
the contract is **fielded** — in the hands of clients you cannot update — or still in active
development. Schema-version bumps, "requires app update" gates, decode-with-default tolerance,
and legacy-format migration paths exist to protect fielded clients. For an unshipped shape, a
contract change is a clean rewrite of every site at once — producer, data, and consumer
together — with no version gate; adding one is ceremony. Judge per contract, not per project:
a multi-consumer library path serving deployed consumers keeps its compat path even while the
app around it is pre-release, and a cross-process wire format is a real contract before it
ships.

## Invariant-first (stateful code)

Applies to any state machine, cache, display contract, sync protocol, retry/recovery
logic, or lifecycle — anything whose correctness is a property over time, not a single
call's return value. In stateful code, review-blocking defects cluster at the invariant
level, and the root cause is pattern-matching a plausible mechanism instead of deriving it
from the property it must maintain. Only process forces derivation.

**At plan time — the design must be so thorough implementation cannot go wrong:**
- Invariants are stated as quantified properties over OBSERVABLES ("no served entry is ever
  staler than its TTL") — never as mechanisms ("the timer clears the entry"). A mechanism
  is proposed only after the property it serves is written; if the property can't be
  written, the requirement isn't understood yet.
- Every invariant of the form "X stays consistent with Y" names its ENFORCEMENT POINT: the
  code location where Y changes. Unnameable ⇒ the invariant is unowned ⇒ the plan is not
  approvable. Reactive enforcement (checked where the value is consumed) requires explicit
  justification of the window between the change and the check.
- Epistemic typing: two values of the same language type carrying different trust —
  measured truth, estimate, derived-for-display — get DISTINCT NAMES at plan time. Every
  comparison, `max()`, or assignment that mixes kinds states which kinds it mixes.
  Truth-only operations (diagnostics, recovery, control decisions, wire payloads) never
  take a display or estimate value.
- Universal quantifiers ("never", "always", "exactly once", "all surfaces") require a
  per-path or per-consumer walk in the plan — or the qualifier that survives one. An
  unqualified claim is a promise to every future reader.
- Design-note review precedes implementation: review the note + plan in a fresh context
  BEFORE writing code. Findings cost sentences there; the same findings post-diff cost
  review rounds.

**TDD — the property test precedes the mechanism:**
- Contract-shaped behavior gets its PROPERTY TEST first: enumerate the event alphabet
  (every mutation the state can receive), write the property over event sequences, watch it
  fail, then build the mechanism until it passes. Unit tests of the mechanism come after
  and cover its edges.
- Every fixture value is load-bearing: a fixture that satisfies assertions vacuously (a
  zero that short-circuits the arithmetic, two values equal by accident) is a lying test.
  State why each magic value sits where it does relative to the property's boundary.

**One authority per invariant.** Every invariant has exactly ONE authoritative statement —
the branch's design note while work is in flight, or the subsystem contract table once it
is standing behaviour. Every other artifact (ADR, glossary, contract tables, test docs,
code comments) POINTS to that authority by invariant name and never restates the mechanism
or its justification. A pointer cannot drift; a restatement is a guaranteed future review
finding. ADRs record the decision and rejected alternatives at decision time; the living
mechanism is described only at the authority. When a change makes the authority's statement
false, updating it lands in the same commit as the code. (Measured, 2026-08-12 gate cycle:
roughly half of all findings across five rounds were restatement drift across six
artifacts — one authority makes the ripple surface one.)

## Tiebreak

When this discipline and delivery pressure conflict, the invariant and type-level work IS
the schedule: plan-time sentences skipped return as full review rounds, with interest.

## Review pass

For reviewing a finished diff or branch (rather than a plan), invoke `design-review-lens` —
the full SOLID/Clean Architecture/GRASP checklist.
