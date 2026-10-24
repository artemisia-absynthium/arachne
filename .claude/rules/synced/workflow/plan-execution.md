---
description: A plan is a machine-local file, never the conversation; a design note when the change does not fit in one sentence; a divergence re-plans only when it changes the approach; wire contracts are specified before approval; the first vertical slice is integration-tested
---

# Planning & Execution Discipline

## The plan is a file

The task plan is the machine-local file plan mode writes (`~/.claude/plans/<name>.md`), never the conversation; it is re-read at the start of each work session on that task, is updated in place as decisions land, and is discarded when the task closes. It is never committed: its residue is the commit and the pull request, where the reason for a change is recorded for the people who read them. The charter (`charter.md`) is task-tier by the same test and shares this lifecycle.

## When a design note exists

A change that cannot be described in one sentence gets a design note at plan time, never reverse-engineered from the finished diff: the types and their responsibilities, state ownership and lifetimes, the invariants the change adds or changes with their enforcement points, and what only hardware can verify — bounded at about eighty lines. It is task-tier: machine-local, read by whoever the owner asks to review it, discarded at close; its residue is the tests that pin its invariants and one comment at each enforcement point saying why. A change that fits in one sentence gets none.

## A divergence re-plans only when it changes the approach

Any unplanned event (see `terminology.md`) is first a diagnosis. A review finding is evidence about the *approach* before it is a requirement to add: the first question is whether the approach can have the property at all, by construction — independently scheduled tasks cannot preserve call order; a remembered flag cannot know that a track finished on its own. If it cannot, the approach changes; it does not grow a construction that fakes the property, because that construction is always available and always locally justified, and every following finding then adds one more.

When the diagnosis changes the approach and the remaining change no longer fits in one sentence, the plan is remade with the change designed in — in plan mode when the owner is there — and the result is **path-independent**: plan and code end up as they would have been had the requirement been known from the start, placed where the design says it belongs, not where it is cheapest to bolt on. Otherwise the fit is stated in one line and work continues. Off-plan fixes never silently accumulate: a trail of reactive "fix X" commits with no plan update is this rule being broken.

## Specify wire contracts before approving the plan

A plan that produces a wire artifact — file format, archive/zip layout, on-disk or remote naming, serialization, encoding — is not approvable until that contract is specified exactly. "Authored as part of this work" is not a spec: every unspecified byte or name becomes a bug the moment the artifact is generated, uploaded, fetched, and parsed end-to-end.

"Exactly" applies to the artifact — every byte and name decided. It does not extend to the code that produces it: a plan or contract never pins implementation locations.

## Integration-test the first vertical slice

Exercise the real end-to-end round-trip on the first vertical slice, not after all sections are built. A green unit-test suite is not integration evidence — it proves the pieces, not the seams. The seams (naming, formats, transport) are where deferred contracts fail.

## Re-ground after a model switch

On a model switch mid-task, re-read the plan and the diff-so-far and reconcile before writing new code. The previous model's implicit context does not transfer; only the durable task plan does — which is the other reason the plan must be a file, and must carry every contract the next model needs.
