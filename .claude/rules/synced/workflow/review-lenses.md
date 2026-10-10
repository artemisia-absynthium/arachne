---
description: One list of review lenses, applied to the design note before code exists and to the diff before close; a finding names the invariant, requirement or reproduction behind it, and a clean result is the expected one
---

# Review lenses — one list, two moments

The same lenses review a design note before code exists and the diff before the task closes.
A lens skipped at note time returns as a review round at diff time, the costlier moment; a lens
that applies only once says so below.

| Lens | At the design note | At the diff | Carried by |
|---|---|---|---|
| Design — responsibilities, boundaries, coupling, precedent, over-engineering | yes | yes | `design-review-lens` skill |
| Types — encapsulation, invariants expressed in the type, lifetimes of its state | yes | yes | the type-design reviewer; `planning-discipline` type-level section |
| Invariants and state ownership — each property named with its enforcement point | yes | yes, as conformance to the note | `planning-discipline` invariant-first; the design lens's conformance check |
| Concurrency — isolation, state across suspension, cancellation, ordering | yes: who owns what, on which isolation | yes | the stack's concurrency review |
| Error handling — every failure surfaces somewhere named, no silent fallback | yes: the error boundaries the note draws | yes | the silent-failure reviewer |
| Omission — null, empty, zero, huge, concurrent and error paths | yes | yes | the brief |
| Tests — property test first, error-path census, falsifiable assertions | yes: the test derivation is part of the plan | yes: coverage of what landed | the test reviewer; `assertions-must-be-falsifiable.md` |
| Security — trust boundaries, secrets, injection, data handling | yes | yes | the brief, or a security reviewer where one exists |
| Complexity and performance — scale stated, asymptotics at realistic scale | yes | yes | `planning-discipline` complexity; the design lens |
| Conventions — the project's own rules | — | yes | the conventions reviewer |
| Comments and docs — accuracy against the code, `docs-sync.md` | — | yes | the comment reviewer |
| Dead code and dead tests | — | yes | the brief |

## The threshold for a finding

A finding names the invariant, the stated requirement, or the reproduction it rests on. A
reviewer asked to find gaps reports some even when the work is sound, so every brief states
that a clean result is the expected outcome of sound work, and that whatever falls short of the
threshold is an observation: reported apart, never a failure. Pre-existing defects in unchanged
code are observations too (`review-before-close.md`). This is the review-side form of
`assertions-must-be-falsifiable.md`: a finding that cannot say what would make it false is not one.

## Who walks the lenses

At the design note, one fresh-context reviewer walks every lens marked for the note in one
brief; a per-lens fan-out runs when the owner asks for one. At the diff, each specialised
reviewer takes its lens, in parallel, one brief each. Reviewers at both moments run on `opus`,
Claude Code's alias "for complex reasoning tasks" (its own reviewer example pins it), set per
invocation in the brief, which overrides a subagent definition's pin. A tool that edits code is not a reviewer:
the simplification pass (`code-simplifier` skill) runs after the task's verification and before
the review pass, so the pass certifies the simplified diff.
