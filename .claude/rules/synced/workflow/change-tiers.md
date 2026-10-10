---
description: Every task opens with a tier line; the tier — set by blast radius and contract impact, never lines of code — decides the treatment, from a direct commit to glossary-first architecture work
---

# Change tiers — proportionate treatment, declared up front

Every task opens with an explicit, owner-vetoable line:

```
Tier: TN because <reason>
```

Classification is by blast radius and contract impact, never by lines of code. Uncertainty
rounds up. The owner can veto the classification; silence is assent.

## The bump rubric — any "yes" moves up one tier

- Changes a wire contract, file format, or on-disk layout?
- Changes a public API, or an invariant in a contract table?
- Adds stored state or a dependency, or touches a concurrency, isolation or error-handling
  boundary?
- Touches more than one package or bounded context?
- Rests on undocumented platform behaviour? This one also means asking the owner before the
  behaviour is changed.

## T0 — Mechanical

Typos, comments, documentation-only changes, log wording: zero executable semantics. Commit
directly, the way the project's git rules say such commits land; no tests, no design note, no
docs line.

## T1 — Local change

A bug fix or tweak inside one component; no contract, invariant or public-API change.

- For a bug, the failing test first — the characterization test is the bug report made
  permanent — then the fix.
- Self-review with every lens in `review-lenses.md`, then the review pass
  (`review-before-close.md`); design-note conformance is not required.
- Impact check: the call sites of anything modified or deleted, and the dead code exposed.

## T2 — Feature within the architecture

New behaviour, type or message; existing boundaries respected.

- **A design note**, written at plan time — never reverse-engineered from the finished diff —
  and bounded, about eighty lines. Sections: *types and responsibilities*, one each; *state
  ownership and lifetimes*, who owns each piece, who resets it, when; *invariants*, only those
  the change adds or changes, one sentence each with its enforcement point — the subsystem's
  existing inventory stays in its contract table, pointed at, never restated; *undecidables*,
  only what hardware alone can verify, each with how it will be demonstrated. Over the bound,
  the change is more than one T2 (split it) or the note restates (cut it), before review. A
  note describing what the code does rather than the constraints that drove it is post hoc,
  and reviewers flag the difference. Where the project keeps its notes is its own instruction
  file.
- **The note reviewed in a fresh context before code**, walking every note-time lens in
  `review-lenses.md`: a finding costs a sentence there and a review round after the diff.
- TDD as `planning-discipline` derives it; docs updated wherever a contract table or reference
  section is touched (`docs-sync.md`).
- **The review pass once, on the final diff.** Design-note conformance is the design lens's
  first job: the code matches the note's types, ownership and invariants; drift in either
  direction is a finding, so is work in the diff the note never mentions, and every unqualified
  universal ("never", "always", "all") gets a per-consumer walk or a finding. After disposal,
  the reviewer reads the note from the commit before its deletion and judges against the
  folded rows.
- **Before merge, in the branch's final commit, dispose of the note**: fold every surviving
  added or changed invariant into the owning contract table — a subsystem with none gets one
  seeded from the note — re-point every reference that named the note at the table, then
  delete the note; history keeps it. A retained note is a second authority
  (`planning-discipline`: one authority per invariant). Nothing is deferred past the merge: a
  disposal step with no PR to carry it never happens.

## T3 — Architectural

A new subsystem, a wire-contract or on-disk-format change, moved ownership or boundaries, a
new dependency, deployed-data impact. In order: the glossary first — every concept the change
touches has an entry, and a new concept is named before it is coded; the strategic pass —
which bounded context owns this, does an aggregate boundary move; the design note plus a
decision record with its rejected alternatives — the record holds the decision, the note the
invariants; the architecture map's delta where containers or components change; contract
tables updated before the behaviour changes; the fresh-context note review, TDD,
implementation; self-review and the review pass, dead code and dead tests removed.

## Session start — the project's memory substitute

Before proposing anything, read what the project keeps, where it keeps it: its router (the
instruction file), its glossary entries for the concepts touched, the contract tables of the
subsystem, its decision records. Which of these exist and where is the project's own
instruction file; that they are read when present is not.

## Anti-ceremony guard

The tier system fails in both directions, and both are flagged. Downward creep: a design note
for a log-line change. Upward creep: a note over the bound, or one restating the subsystem's
inventory instead of pointing at its contract table — enumeration is not rigor. The rubric,
not caution, decides the tier; the bound, not thoroughness, sizes the note.
