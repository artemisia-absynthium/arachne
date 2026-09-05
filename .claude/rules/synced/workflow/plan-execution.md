---
description: Planning and execution discipline for non-trivial, multi-step work
paths:
  - "**/*"
---

# Planning & Execution Discipline

## Plans are durable artifacts, not conversation state

A plan for any multi-step task must live in a durable file (e.g. `~/.claude/plans/<name>.md`), not solely in the conversation. Long conversations are summarized on context compaction, and a plan held only in chat history is the first thing lost. Re-read the plan file at the start of each work session; update it in place as decisions land.

## Divergence is a re-plan trigger

When execution diverges from the approved plan — an assumption breaks, the real system differs from the spec, a step surfaces unknowns — STOP and update the plan before continuing. Off-plan fixes must never silently accumulate; one divergence is a re-planning checkpoint, not a patch. A trail of reactive "fix X" commits with no plan update is the signature of this rule being violated.

## Specify wire contracts before approving the plan

A plan that produces a wire artifact — file format, archive/zip layout, on-disk or remote naming, serialization, encoding — is not approvable until that contract is specified exactly. "Authored as part of this work" is not a spec: every unspecified byte or name becomes a bug the moment the artifact is generated, uploaded, fetched, and parsed end-to-end.

## Integration-test the first vertical slice

Exercise the real end-to-end round-trip on the first vertical slice, not after all sections are built. A green unit-test suite is not integration evidence — it proves the pieces, not the seams. The seams (naming, formats, transport) are where deferred contracts fail.

## Re-ground after a model switch

On a model switch mid-task, re-read the plan and the diff-so-far and reconcile before writing new code. The previous model's implicit context does not transfer; only the durable plan does — which is the other reason the plan must be a file, and must carry every contract the next model needs.
