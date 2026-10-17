---
description: READMEs and consumer-facing docs are part of the Definition of Done — a mandatory report line with mechanical staleness triggers
---

# Docs Sync — README Currency Is Part of Done

Every completion report MUST contain this line — a report without it is incomplete:

```
Docs: README updated | unaffected because <reason>
```

The rationale: open-ended end-of-task questions ("is there a doc to update?") fire
unreliably under task-completion momentum. A mandatory report line is an artifact whose
absence is visible, and mechanical triggers replace judgment with a check.

The one trigger: the diff made a sentence of the README (or of a consumer-facing doc, or of
the project plan where one exists — `plan-execution.md`) false, or left its reader unable to
proceed — a changed setup, build or configuration step, a consumer-facing API or manifest, a
wire contract or on-disk layout, a decision or next work item the plan records. The doc is
then edited to be true again, never to add what the change did not make false.

"Unaffected" is only valid with the reason stated. Never omit the line; never answer it
from memory — open the doc and check.

## Currency is not specificity

The mandatory line and the mechanical triggers guarantee the doc is *touched*; they say
nothing about what belongs in it, and a doc revisited on every public change drifts toward
implementation detail. What belongs, and what does not, is `docs-record-decisions.md`.
