---
name: readme-drafting
description: Act as the repository's maintainer writing for its reader, never as the engineer documenting what was built — the reader is the consumer of a library or tool, or the contributor to an application, and only what that reader needs to act on makes it into the file. Invoke whenever README.md or a repository's top-level guide is written or edited.
---

# README — the maintainer writes for the reader

A README has one reader and one job: get that reader to the thing the repository is for. The
developer's reflex is to document the system as built — how the sync converges, what the script
does step by step, who owns which path; every one of those sentences is true, and the reader
does not need it.

## 1. Name the reader before touching the file

One line, stated before editing:

- **A library, package, action or tool** → the reader is its *consumer*: someone who will install
  it, use it, configure it, and maybe contribute. They never open the internals.
- **An application or service** → the reader is its *contributor or operator*: someone who will
  build it, run it, test it, release it, and find where things are.

Everything else — the maintainers' contracts, the design reasons, the script internals — has a
home that is not the README: `CLAUDE.md`, `.claude/rules/`, or a document the reader is
pointed to only when it exists.

## 2. One test per sentence

*Which action of the reader needs this sentence?* Install, run, configure, verify, contribute,
find. A sentence with no action behind it goes. What typically fails the test: ownership and
deletion tables, numbered walkthroughs of what a script does, architecture and rationale, history
("previously", "moved from"), counts, TODOs, anything written for the person who maintains the
repository rather than the one who uses it.

## 3. The shape, each section only when the reader needs it

What it is (one paragraph) · quick start · what you get or how to use it · configure · run,
test or deploy (applications) · contribute. A reference table of options or categories belongs
here only when the reader chooses among them; a catalog the reader can browse in the tree is
pointed at, not copied.

## 4. The subtractive pass before reporting

Read the result as the reader, top to bottom: every sentence either moves them to the next step or
is cut. A README the reader cannot finish in one sitting has a maintainer's document inside it;
move that document out rather than trimming words.

**Why (owner, 2026-10-21):** the README of a shared-rules repository had grown to 180 lines —
an ownership-and-deletion contract, a seven-step account of what the setup script does, the
action's internals — written in the developer's role over months of edits, each one true. The
consumer needs the one-command setup, the categories, the deploy key and how to contribute: 90
lines. The rest moved to a maintainer rule the consumer never loads.
