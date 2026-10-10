---
description: How findings are communicated, for reviewer and author alike — one complete fix shape, majors self-verified before posting, errors conceded on the record, device evidence once on the final HEAD, gating the merge
---

# Review discipline — symmetric, for author and reviewer alike

These rules apply in both directions: today's reviewer is tomorrow's author. Multi-round review
dances are almost always caused by process, not by hard code, and each rule below is named after
the failure it prevents. What a finding rests on is `review-lenses.md`; what the author does with
one is `respond-to-pr-review`. This rule is about how a finding is communicated.

## Reviewer side

- **State the invariant first, then the finding.** A comment that only describes a failure
  scenario invites a patch scoped to that scenario: the invariant is the requirement, the
  scenario is evidence. A fix satisfying the invariant closes every scenario; a fix satisfying
  the scenario spawns the next round.
- **Give one complete fix shape — never a minimal variant alongside it.** When a quick fix and a
  robust fix are both described, the minimal one gets taken, and the difference returns as the
  next round's major. Signatures over prose where possible.
- **Self-verify every major-class claim before posting** — by a direct read at the branch head,
  or by a minimal compile or run reproduction. A refuted major costs the author a round and the
  reviewer trust. A subagent's finding is a hypothesis until verified.
- **Concede errors on the record.** A wrong suggestion, once discovered, is corrected explicitly
  in the next review — never silently dropped.

## Author side

- **Reply in-thread before pushing a fix for a major**: restate the invariant you understood
  and the fix shape you intend. Minutes of asynchronous dialogue replace whole rounds spent
  discovering a misunderstanding after the code exists.
- **Device or hardware evidence belongs to the author, and runs exactly once — on the final
  HEAD.** Behaviour the simulator or CI cannot exercise (offline media, real transport drops,
  sensor paths) is verified on hardware with the evidence in the PR body. Sequence it last: all
  review rounds resolved, the final HEAD pushed, then the single device pass. Never request a
  device run mid-loop — any code change after the run invalidates its evidence and forces a
  repeat of someone's hardware time. The device pass gates the merge, not ready-for-review: a PR
  may go ready with the evidence stated as owed before merge.

## Both sides

- Findings are resolved or explicitly acknowledged — never silently dropped.
- Anything resting on undocumented platform behaviour in a load-bearing path is a design
  finding, not a style note: design it away or demonstrate it empirically.
