---
description: What reviewers keep finding, stated as write-time rules — one copy of any logic, bounded per-update work, invariants with an enforcement point, value edges, failures that surface, measured platform claims, falsifiable tests, the convention over the legacy file, role-and-symbol references, comments only for what the code cannot say
---

# Write it right the first time

Each line is a finding a human reviewer opened more than once on reviewed changes. Apply it while
writing; none of it needs a review pass to be checked. The stack's own file adds the
language-specific lines (`swift/write-time-checklist.md` for Swift).

- **One copy of any logic.** The same decision in two places is one helper, or one of them is
  deleted — never a second copy "for now". A redundant call or write (a sync already done, a read
  already made) goes.
- **Per-update work is bounded.** Code on a per-frame, per-event or per-update path does bounded
  work; a set, cache or queue that only grows is a defect, and the bound is stated where the
  collection lives.
- **An invariant names where it is enforced.** For a state machine, every mutation of the state
  goes through the point that enforces its invariant; "it holds on the paths I thought of" is the
  finding.
- **Value edges are written, not assumed.** Missing, empty, whitespace-only, indefinite, and
  changed mid-flow each have their path.
- **A failure surfaces somewhere named.** An error is handled, returned, shown or logged. It is
  discarded only when it cannot reach the user *and* a log line would say nothing — the failure is
  expected, or outside our control — and the site says which.
- **A platform claim is measured or cited at the site.** Nothing load-bearing rests on
  undocumented platform behaviour; a delay or threshold states what measurement chose it.
- **Every test names the mutation that turns it red** (`assertions-must-be-falsifiable.md`); a
  test that stays green when the guard is removed is filler.
- **Follow the convention, not the legacy file.** Logging, isolation style and file layout follow
  the project's stated convention; a file still on the old one is not the template.
- **Refer by role and symbol**, never by position, and never count in prose: a count is stale at
  the next edit, and the list is the count.
- **A comment says what the code cannot.** A comment exists only for what a reader cannot learn
  from the code, at the site or by following its references: a public symbol's contract for its
  callers, or the reason behind a choice someone would otherwise undo, with its source when the
  reason is external.
