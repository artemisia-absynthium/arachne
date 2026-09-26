---
description: Plans are durable artifacts in two tiers — task plans machine-local and uncommitted, project plans in the repo and committed with the code; divergence re-plans, contracts precede approval
---

# Planning & Execution Discipline

## Plans are durable artifacts, in two tiers

A plan never lives only in the conversation: long conversations are summarized on context compaction, and a plan held only in chat history is the first thing lost. Which durable home a plan gets depends on its lifetime (*task plan* and *project plan* are defined in `terminology.md`), and the test is who reads it next.

- **Task plan** — one task, one session, one branch. Lives in a machine-local file (e.g. `~/.claude/plans/<name>.md`): durable across compaction, re-read at the start of each work session on that task, updated in place as decisions land, discarded when the task closes. Its only residue is the commit and the project plan's status update. It is never committed to the repo. The charter (`charter.md`) is task-tier by the same test and shares this lifecycle.
- **Project plan** — what the *next session* must read to plan the next step: the roadmap with a `## Now` pointer to the next work item and its gate, the dated decision log, the design and its invariants. Lives in the repo (e.g. `docs/ROADMAP.md`, `docs/DESIGN.md`), is updated **in the same commit** as the code that changes it (a staleness trigger in `docs-sync.md`), and is never machine-local — a plan only one machine can read does not survive a new session, a new machine, or a new collaborator.

**The test:** if the next session needs the file, it is project-tier; if it only needs the outcome, it is task-tier. A decision made inside a task plan that outlives the task migrates to the decision log at task close; the task plan itself does not. The charter's `Now:` is the current step *within* the task; the roadmap's `## Now` is the next work item *across* sessions.

Rationale: a project-scale plan kept in the machine-local task location serves the session that writes it and leaves nothing a fresh session can resume from; the gap surfaces only when a later session is asked to "plan the next step" and finds no repo artifact naming it. Tiering by lifetime makes the location follow the plan's reach instead of the habit of the session that wrote it.

## Divergence is a re-plan trigger

Any unplanned event (see `terminology.md`) is a divergence. The next output is a diagnosis and a *proposed* change, never the change itself.

A review finding is a divergence, and it is evidence about the *approach* before it is a requirement to add. The first question is whether the approach can have the property the finding says is missing — at all, by construction. Independently scheduled tasks cannot preserve call order; a remembered flag cannot know that a track finished on its own. If the approach cannot have the property, the approach changes. It does not grow a construction that fakes the property, because that construction is always available and always locally justified, and every following finding then adds one more.

The change must be **path-independent**: plan and code end up as they would have been designed had the requirement been known from the start — the simplest structure that satisfies everything now known, with the change placed where the design says it belongs, not where it is cheapest to bolt on. If the plan absorbs it that way, amend it in place; if not, remake the plan with the change designed in. The task plan is what a divergence amends; when the divergence changes a decision, a gate, or the next work item, the project plan (roadmap `## Now`, decision log, design) changes in the same commit as the code. A patch a reader could identify as "added later" — extra branches where a model should have changed, a step bolted beside the one it contradicts — is a Frankenstein, and every later step inherits the seam. Off-plan fixes must never silently accumulate; a trail of reactive "fix X" commits with no plan update is the signature of this rule being violated.

## Specify wire contracts before approving the plan

A plan that produces a wire artifact — file format, archive/zip layout, on-disk or remote naming, serialization, encoding — is not approvable until that contract is specified exactly. "Authored as part of this work" is not a spec: every unspecified byte or name becomes a bug the moment the artifact is generated, uploaded, fetched, and parsed end-to-end.

"Exactly" applies to the artifact — every byte and name decided. It does not extend to the code that produces it: a plan or contract never pins implementation locations, and how an enforcement point is named is `docs-record-decisions.md`.

## Integration-test the first vertical slice

Exercise the real end-to-end round-trip on the first vertical slice, not after all sections are built. A green unit-test suite is not integration evidence — it proves the pieces, not the seams. The seams (naming, formats, transport) are where deferred contracts fail.

## Re-ground after a model switch

On a model switch mid-task, re-read the plan and the diff-so-far and reconcile before writing new code. The previous model's implicit context does not transfer; only the durable task plan does — which is the other reason the plan must be a file, and must carry every contract the next model needs.
