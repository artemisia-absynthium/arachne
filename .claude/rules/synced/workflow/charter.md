---
description: Per-task charter — the concerns that must stay true and what done means, each with its source, held as a gitignored local rule so it survives compaction and reaches every brief and every commit
---

# Charter — what must stay true for the task

A charter is the short list of concerns a task must keep true from start to finish, held
explicitly so it survives long sessions, context compaction and delegation. It exists when a
plan does — a change that cannot be described in one sentence — and never otherwise.

## Shape — about ten lines

```
# Charter — <task>
Must stay true: <concern> (<source>) · <concern> (<source>) · …
Done means: <the observable, not the step list>.
```

Every "must stay true" line carries its source: the owner said it, a named caller depends on it
(the `Consumers:` entry in the plan), or a test pins it. A line with none of those is a
preference the author added, and it does not belong here: "public API stays unchanged", written
because it felt safe, becomes a constraint every later decision pays for in mechanism, and nobody
asked for it. With a source required, the line either names who needs it or does not get written.
That is the difference between a charter and a cage.

## Where, and why there

`.claude/rules/charter.local.md` in the repository, with `.claude/rules/*.local.md` in its
`.gitignore` and **no frontmatter**: an unscoped rule is re-read from disk after every
compaction, which is what keeps the charter in context without anyone restating it, and a
`PreToolUse` hook on `git commit` reads it at the moment it matters. The plan's first line links
it. It is copied into every brief handed to a subagent, and every return is read against its
lines (`delegation.md`). It is discarded with the plan; its residue is the commit and the pull
request. *Done* (`terminology.md`) means its lines hold, with evidence.
