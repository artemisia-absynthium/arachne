---
description: Definitions other rules cite — fix vs workaround, the authority order of sources, done, unplanned event, task plan vs project plan
---

# Terminology

Words other rules lean on. One definition each; rules cite these instead of restating them.

## Fix

A change whose cause is named, whose remedy is the one prescribed by an authoritative source
(or, absent one, derived from the source itself and shown correct), and whose effect is verified
at the gate. *"Cannot be fixed correctly"* is a valid outcome of a fix attempt, reported as such.

## Workaround

Any change that makes a symptom stop without the above: iterating until it passes, switching
tool or invocation to avoid the error, suppressing a diagnostic. Never silent — proposed, named
as a workaround, accepted only by the owner.

## Authoritative sources

In order of authority:

0. **The artifact itself** — source code, headers and interfaces, the specification, measured
   behaviour of the real system. Outranks documentation when they disagree; the disagreement is
   reported.
1. **Official documentation** of the technology.
2. **Other official channels** — the vendor's website, forums, repositories and changelogs, and
   *identified* employees or maintainers speaking on third-party sites (a vendor engineer
   answering on Stack Overflow or Reddit under their name — never an anonymous account).
3. **Recognized experts** — books, talks, their own sites. *Expert* means universally
   recognized on that subject: their work is the canonical reference and is taught in
   university CS curricula. Canonical and taught, not well-known.

**Tertiary — a pointer, never an authority:** anonymous Stack Overflow or Reddit answers, blogs
by unidentified authors, AI output including the assistant's own recall. It may say where to
look; the claim is confirmed at levels 0–3 before use and cited with it. When only tertiary
exists, the claim is stated as unverified.

## Done

The charter is satisfied with evidence (see `charter.md`), not the step list exhausted.

## Unplanned event

Anything not in the approved plan: a failing command, a surprising result, a changed setting or
requirement, a question from the owner, an interruption.

## Task plan

The plan for one task on one branch, read only by the session(s) executing it: machine-local,
never committed, discarded at task close. The charter is task-tier. Discipline in
`plan-execution.md`.

## Project plan

What the next session must read to plan the next step — roadmap with a `## Now` pointer,
dated decision log, design and invariants: in the repo, committed with the code that changes
it, never machine-local. The test between the two tiers: if the next session needs the file, it
is project-tier; if it only needs the outcome, it is task-tier.
