---
description: Per-task charter — the concerns that must stay true, held as an unscoped gitignored rule so they survive compaction and delegation
---

# Charter — what must stay true for the task

A charter is the short list of concerns a task must keep true from start to finish — the
holistic picture, held explicitly so it survives long sessions, context compaction and
delegation. Invariants do this for the codebase; the charter does it for the work.

## Where

`.claude/rules/charter.local.md` in the repository, gitignored (`.claude/rules/*.local.md`).
It has **no frontmatter**: an unscoped rule is re-injected from disk after every compaction; a
`paths:`-scoped one is not. The charter is **task-tier** (see `terminology.md`): it lives and
dies with the task plan, never in the repo's project plan.

## Lifecycle

- **Written** in plan mode at task start, before the first step — then read immediately so it
  is in context now (a rule file created mid-session is otherwise loaded only at the next launch
  or compaction), and linked as the task plan's first line
  (`Charter: .claude/rules/charter.local.md`) so reading or executing the plan forces reading it.
- **Updated** at every divergence, in the same pause that produces the diagnosis
  (see `plan-execution.md`).
- **Re-read** before every commit, and copied into every brief handed to a subagent.
- **Checked** at task close: every "must stay true" line answered with evidence, never
  asserted. *Done* means the charter is satisfied (see `terminology.md`).
- **Drained** at task close: every decision under `Waiting on the owner` that was resolved,
  and every decision taken during the task that outlives it, is written to the project plan's
  decision log (see `plan-execution.md`) before the charter is discarded. A decision that
  exists only in a gitignored file is lost with it.

## Shape — concerns, not steps; about fifteen lines

```
# Charter — <task>
Goal: <one sentence — the observable outcome>.
Must stay true: <architecture boundary> · <concurrency model> · <UI/UX> · <performance on
  the weakest supported tier> · <testability and the gate> · <evidence> · <docs> ·
  <invariants touched>.
Done means: <the observable, not the step list>.
Now: <the current step within this task — not the roadmap's next work item>.
Waiting on the owner: <open decisions, verbatim>.
```
