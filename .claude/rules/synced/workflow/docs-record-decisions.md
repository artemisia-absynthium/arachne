---
description: Docs, design notes and doc comments record decisions and invariants, never facts about the current text — cite code by symbol and role, never by line; path:line belongs in conversation only
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

## Two tests, applied to every sentence

- **Could a script check it?** Then it is a test or a lint, not prose. Write the check, or
  write the *reason* instead — a decision does not rot, a count does.
- **Would a rename or a moved line break it?** Then it names a location, not a role.

A baseline a run is judged against — the `totalTestCount` of `xcode/test-verification.md` —
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

A multi-line doc comment defending a non-obvious invariant is either a missing test or a
required justification; `assertions-must-be-falsifiable.md` says which.
