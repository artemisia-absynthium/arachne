---
description: Cross-language code style — new code follows the convention even where its neighbours do not; conventions adopted after the code are fixed on touch, never in a sweep; a task changes nothing it did not call for; prose refers to code by role and symbol
---

# Code Style

## Pre-existing violations

When surrounding code violates a project convention, new code still follows the rule — never
mirror a violation because the neighbours do it. Stop the bleeding; don't match bad neighbours.
The violation itself is left as it is: fixing it is not this task's work, and a sweep as part
of unrelated work produces noisy diffs and risks regressions for no behaviour.

## Conventions adopted after the code — fix on touch, never sweep

A convention adopted after code exists leaves files carrying the old one. Those files are
fixed when a task touches them — the import order, the file header, whatever the convention
names — and never in a sweep: a sweep is diff noise that hides the change under review and
risks regressions for no behaviour. Which conventions a project adopted this way, and what
the old form looks like, is the project's own instruction file; the rule above keeps covering
every file a task does not touch.

## Scope of a change

A task adds no document, and no cleanup it did not call for, of its own: nearby debt, a
pre-existing bug, behaviour the task does not mention are suggestions at the end of the work,
never changes in it.

## Documents

In prose that outlives a commit — a README, a doc comment, a rule file — refer to code by role and
symbol, never by position.

## Scope: style, not design

This rule governs *style and convention* — naming, formatting, logging, file layout. It
does not make existing *design* a baseline to preserve. Reluctance to touch what is not
in the way is good practice; treating an existing structure as a requirement because it
exists is not. When keeping a structure starts costing a mechanism, the structure has to
justify itself, and that judgment is `planning-discipline`, question 2.
