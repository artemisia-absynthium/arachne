---
description: READMEs and consumer-facing docs are part of the Definition of Done — a mandatory report line with mechanical staleness triggers
paths:
  - "**/*"
---

# Docs Sync — README Currency Is Part of Done

Every completion report MUST contain this line — a report without it is incomplete:

```
Docs: README updated | unaffected because <reason>
```

The rationale: open-ended end-of-task questions ("is there a doc to update?") fire
unreliably under task-completion momentum. A mandatory report line is an artifact whose
absence is visible, and mechanical triggers replace judgment with a check.

Mechanical triggers — the README (and any consumer-facing doc) is presumed STALE and must
be diffed against the change whenever the diff touches:

- a public declaration (API added / changed / removed)
- the package/build manifest (products, targets, dependencies, platform floors)
- a wire contract, file format, or on-disk layout
- a setup, build, or configuration step

"Unaffected" is only valid with the reason stated. Never omit the line; never answer it
from memory — open the doc and check.
