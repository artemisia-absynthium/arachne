---
description: Docs, design notes and doc comments record decisions and invariants, never facts about the current text — cite code by symbol and role, never by line; path:line belongs in conversation only; a count in prose is removed when found, never updated
---

# Documentation Records Decisions, Not Code State

Docs, design notes, contract documents and `///` doc comments describe **what is decided** —
the architecture, the invariants, the constraints, and the reasons behind them (the project
plan's "design and its invariants", see `plan-execution.md`). They never describe **the
current state of the text**: line numbers, statement or member counts, grep results, file
lengths, test counts, "the only two call sites are …".

The rationale: a fact about the text is true at the commit that wrote it and silently false
at the next edit. Nothing marks the transition — a red test or a compile error announces
itself, a stale number does not. On a WIP branch this happens before the PR is even opened: a
contract written ahead of the code (the right order) that pins *where* the code will live
(the wrong content) is wrong by the second implementation commit.

## `path:line` is for conversation, not for documents

Citing code as `path:line` is right in chat, in a review comment and in a commit message —
each is attached to a moment and a commit, and the reference is clickable there. It is wrong
in anything committed as documentation or written as a doc comment: those outlive the commit.
The habit does not cross the boundary. In a durable text, refer to code by **role and
symbol** — a symbol is found by the compiler and by grep when it moves; a line finds nothing.

## The tests, applied to every sentence

- **Could a script check it?** Then it is a test or a lint, not prose. Write the check, or
  write the *reason* instead — a decision does not rot, a count does.
- **Would a rename or a moved line break it?** Then it names a location, not a role.

A baseline a run is judged against — the executed-test count a suite is expected to reach —
is an input to a check, not prose: it lives where the check reads it (a CI variable, an
assertion), never in a document.

```
✅  Both ownership writers, `register(_:for:)` and `unregister(id:)`, clear the flag —
    no other path mutates `owners[id]`, so a flag can never describe a stale owner.

❌  `register` (L415) and `unregister` (L421) are the only writers of `owners[id]`
    (`grep -c "owners\[id\] = "` = 2).
```

A contract states each invariant and its **enforcement point by role** — the type or function
responsible. A walk-through citing `L57`, `:412` or "the guard two lines above" is an
implementation snapshot, not a contract.

Never count items in prose ("the nine defects below"). The list is the count; the sentence is
stale the moment an entry is added.

## A count found in prose is removed, never updated

The rule above governs writing. This one governs reading: the moment a sentence carrying a count
is in front of you — an edit touches it, a doc you are citing contains it, a review covers it —
the number is deleted and the list it duplicated carries the figure. Updating it in place
("three apps" edited to "two apps" when a target is removed, "seven identity values" to "five")
is the failure mode, not the fix: the sentence is true again for exactly one commit, and the next
change to the list pays the same edit. A sweep that renames a number everywhere it appears is the
rot being maintained with care.

This is the one pre-existing violation `code-style.md`'s TECH-DEBT deferral does not reach,
because neither of its reasons applies: deleting a number from a sentence changes no behaviour,
and a one-word change in a document is not diff noise. In an author's hands the removal rides in
the commit that touches the file; in a reviewer's, a count on a line the diff touches is a
finding, and one in a passage the review read is named for the author to remove in the same pass.
The only count that stays is the one that was never prose: an input to a check, kept where the
check reads it (above).

## A count is never evidence — PR bodies, commit messages and reviews included

The `path:line` exemption for conversation does not extend to counts. A PR body, a commit message
and a review comment carry no totals, no baselines, no occurrence or line counts: a verification
line says that the test-count check is green on the final head's result bundle, never what the
number was, and the baseline it was judged against lives only where the check reads it.

On the reading side a reviewer ignores every count it meets — it never reconciles one, disputes
one, or reasons from one. A finding stands on the defect: a test that cannot finish, a row the
code cannot hold, a contract two documents state differently. A figure found in prose is a
one-line removal item in the same pass, never a thread. Rationale: an argument over a count is an
argument about the state of the text, which the check settles mechanically and a review cannot;
every exchange spent on it is taken from the defect, and the number is stale before the exchange
ends.

A multi-line doc comment defending a non-obvious invariant is either a missing test or a
required justification; `assertions-must-be-falsifiable.md` says which.
