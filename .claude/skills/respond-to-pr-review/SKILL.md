---
name: respond-to-pr-review
description: The procedure for acting on a received PR review — per finding, whether it is about this PR, whether the approach can have the property by construction, the correct remedy whatever its size, and whether that remedy fits the PR (out of scope is recorded, never replaced by a smaller remedy); the response, side-work ledger included, is a draft the owner approves before any code, and that approval publishes it once the fixes are in, unless something new came up or a remedy awaits the owner's own check; replies and resolves go through the API that actually resolves each thread. Invoke the moment a review arrives (a CHANGES_REQUESTED state, new review threads, "the PR has been reviewed"), before replying to or fixing anything.
---

# Respond to a PR review

The failures this exists to prevent:

- Fixing each finding where it sits until the design is a pile of patches, each one
  locally justified by the one before it.
- Choosing a remedy by its size: a patch that fits the PR in place of the correct design,
  admitted at a price nobody wrote down, until it draws review rounds of its own.
- Publishing a response the owner never approved, so the reviewer reviews work the
  owner never saw.
- Leaving threads unresolved, which blocks the merge under branch protection and,
  without it, reads to the reviewer as work still pending.

## 1. Read everything, from the objects that actually hold it

A review lives in several GitHub objects, and only the inline threads can be resolved:

| Object | Where | Resolvable |
|---|---|---|
| Review body and state (`APPROVED`, `CHANGES_REQUESTED`) | `gh pr view <n> --json reviews` | No — answered by a comment and a re-requested review |
| Inline review threads | GraphQL `pullRequest.reviewThreads` — each with `id`, `isResolved`, `path`, `line`, `comments` | **Yes**, and only through GraphQL |
| Issue comments | `gh pr view <n> --json comments` | No |

Read every one before forming a view. The inline threads are the ones that get lost:
they are not in the review body, and a `gh pr view` does not show them.

```sh
gh api graphql -F owner=<owner> -F repo=<repo> -F number=<n> -f query='
  query($owner:String!, $repo:String!, $number:Int!) {
    repository(owner:$owner, name:$repo) { pullRequest(number:$number) {
      reviewThreads(first:100) { nodes {
        id isResolved isOutdated path line
        comments(first:50) { nodes { databaseId author { login } body } }
      } }
    } }
  }'
```

## 2. Is the finding about this PR?

For every finding, one written line before step 3:

```
<finding> — about this PR? <introduced | touched | no> — <the argument>
```

- **No — the base branch has the same defect**, and the diff neither introduced nor
  touched it → an observation (`review-before-close.md`). No fix in this PR: it is
  recorded where `side-work.md` records backed-out work, and the reply says where.
- **Introduced or touched** → step 3. Which one it is matters only when step 4 finds
  the remedy does not fit.

## 3. Before any fix: can the approach have this property by construction?

For every finding step 2 kept in this PR, one written line before touching code:

```
<finding> — can the current approach have this property by construction? <yes | no> — <the argument>
```

- **Yes, the code just fails to do it** → the approach stands, and the remedy is
  designed below.
- **No** → the approach is dead *for that property*. It does not get a construction bolted
  on that fakes the property; that construction is always available and always locally
  reasonable, which is exactly why it must not be the default. Go back to the questions
  `planning-discipline` asks before any design. The answer to the review is then a
  design, not a list of fixes, and the reply says so.
- **Several "no"s** → the approach is dead, full stop. Read the review that way.

Remedies are generated before they are judged: a rule applied after the design can only
filter the candidates that were generated (`planning-discipline`). The candidates come
from its alternatives question — simplest first, and one of them deletes or replaces —
and from the precedent its "Solutions are rooted in the literature" section names. A
reviewer's *suggested* remedy is one candidate, not a requirement. "Do X, or scope down
and open a follow-up" is not an order: X joins the candidates, and whether to scope down
is step 4's to decide.

The **correct remedy** is the candidate that is a fix in the sense of `terminology.md`,
passes every lens in `review-lenses.md` at the moment that lens applies — the criteria a
review measures the result against — and is path-independent (`plan-execution.md`),
placed where the design says it belongs, as if the requirement had been known from the
start. A lens skipped here returns as the next review round. Neither its size nor the
order the reviewer offered it in chooses it. When more than one candidate passes, the
simplest wins in the alternatives question's sense — what a reader must hold in their
head, not a count of anything. When none passes, step 4's line puts "cannot be fixed
correctly" (`terminology.md`) in its remedy slot, names per candidate what it failed —
being a fix, each lens it failed, or path-independence — and answers the fit question
"no — cannot be fixed correctly". Step 4 carries this one remedy and never picks a
different one.

The argument is what makes this step honest rather than a table to fill in: "yes,
independently scheduled tasks preserve call order because…" cannot be finished, and a
line that cannot be finished is a "no".

**Unsure is a valid answer**, and it is not resolved by guessing. It becomes a question
to the reviewer in the draft, and the PR waits for the answer.

**Why:** a first review said an approach preserved order "by luck rather than by
construction". The response added a construction that preserved it. The second review
found the same class of finding again and again — the approach cannot observe X by
construction — and the response was a patch for each. The owner then rewrote the feature
in an afternoon by replacing the type, an option that had been available since the first
finding and was never generated, because every finding had been read as "add what fixes
this" and none as "this cannot be fixed from here".

## 4. Does the correct remedy fit this PR?

For the remedy step 3 settled on, one written line before touching code:

```
<finding> — <the correct remedy; the lenses that chose it> — fits this PR? <yes | no> — <the scope signals it trips>
```

The scope signals are read off the remedy, never argued:

- it touches a file the change did not otherwise need;
- it adds an invariant, an enforcement point (a check, a guard, a validation), a contract
  clause or a CI step;
- a question of the bump rubric in `change-tiers.md` answers yes for it, whatever tier
  the change is argued to stay in.

A remedy that trips one does not fit, and an unsure fit does not fit either, the way
`change-tiers.md` rounds an uncertain tier up. "Cannot be fixed correctly" does not fit.

- **Fits** → proposed in the draft as this round's fix.
- **Does not fit, the defect touched** → proposed in the draft as out of scope: the
  remedy is recorded where `side-work.md` records backed-out work, and this PR changes
  only what keeps its own statements true about the defect as it stands — a sentence
  that would claim the missing property says it is missing ("enforced by nothing").
  Taking the remedy on anyway is side-work.
- **Does not fit, the defect introduced** → out of scope too, and the draft puts the
  ways out to the owner with no default: the part of the change that introduced the
  defect is backed out, or the PR ships with the defect stated and recorded. Taking the
  remedy on anyway is side-work here too.

A smaller remedy is never put in the correct one's place because the correct one is too
big: that substitute is the bolted-on construction step 3 rules out, and it is not among
the options.

**Why:** a reviewer found that nothing enforced a setting the PR had just moved, and
offered either a guard or the caveat the neighbouring invariants already carried. The
response took the guard, a check of one key beside the general comparison a later round
named as the real fix. It priced the guard in words as "one guard check", argued the
tier bump down on that price, and closed with "veto if you want the full T2 path"; it
then built the guard when a background report arrived, before any answer. The guard grew
into a script change, a new contract invariant, a CI edit and a backlog entry, and drew
most of the findings in the rounds that followed, one round fixing the previous round's
fix. The branch was rebuilt from the base, its text saying the setting is enforced by
nothing.

## 5. The draft — the response, approved before any code

The response to a review is a draft the owner approves before anything is built or
posted. It carries:

- per finding, its lines from steps 2 to 4 and the proposal;
- **the side-work ledger**: every piece of side-work on the branch, from the task plan
  where `side-work.md` keeps it — what it is; its price, the kill criterion; whether it
  is new this round or carried from an earlier one; and for carried side-work, the price
  it was admitted at against what it has cost so far, and whether it is now over. Over
  its price, the proposal is to back it out (`side-work.md`). In a review round only the
  owner admits side-work, even where a rule would admit it elsewhere;
- verbatim, every reply the round will post — each major's intent reply
  (`review-discipline.md`), each question for the reviewer, each closing reply with its
  commit left to fill in, and the resolve that goes with it — then, when the round has
  them, the push of its commits and the re-request;
- per remedy, the verification it re-runs and the result expected, and whether its
  behaviour needs the owner's own check before it leaves the machine
  (`git-discipline.md`);
- when the round has fixes, its own verification — build, suite, the project's gates —
  and the result expected.

It goes to the owner as a blocking question (`AskUserQuestion` in Claude Code): each
item approved or denied, each choice chosen, and nothing is built or posted until the
answer arrives. A denied item sends the draft back with what replaces it; only a draft
approved whole, a chosen option counting as approved, goes further. A subagent report, a
task notification or a finished build is not an answer, and neither is an instruction
given before the draft existed: "respond to the review", "address the findings", "fix
them and push" ask for the draft, not for its approval. "Veto if you want …" is not a
question: it is the decision, taken in advance. The silence-is-assent of
`change-tiers.md` covers the tier line alone; it never waives a tier's treatment, admits
a remedy that does not fit, or admits side-work.

On whole approval, the questions and the intent replies are posted at once, the way
step 7 posts them. When a question went to the reviewer, the intent replies wait with
the fixes, since the answer can change their fix shapes; nothing is fixed until it
arrives, and the answer then enters at step 2 and the draft is redone. The rest of the
approval covers publishing the response once the fixes are in, with no second go beyond
the owner's check of a remedy the draft marks for it: in this procedure the approval is
the owner's word for the round's push, given in advance for exactly this draft and void
on any divergence.

## 6. Fix locally, re-review, then publish the approved draft

- Each approved remedy gets, before any code, the treatment its own tier sets in
  `change-tiers.md`; the tier is the remedy's, never argued down on its price. Then fix,
  and re-run the verification the draft lists for it.
- Once every remedy is in, re-run the round's verification the draft lists.
- The round's delta is re-reviewed in a fresh context (`review-before-close.md`).
- Squash the round's fix commits locally (`git-discipline.md`).

**Anything new goes back to the owner before anything is published.** A divergence
during the fix (`plan-execution.md`) — a remedy that comes out different from the
approved one, a scope signal it now trips, side-work past its price, any verification
result other than the one the draft expects (one judged noise included; it enters at
step 2 like a finding, and a fix for it is a new remedy), a finding of the re-review, a
new comment from the reviewer — changes the draft, and the changed draft is approved
the way step 5 asks. A remedy marked for the owner's check waits for that check, and a
check that fails is a divergence too. Otherwise step 7 publishes the approved draft as
it stands: filling in a commit reference changes nothing in it.

**Why:** review rounds were pushed and answered on "respond to the review" alone, one
after another, and the reviewer reviewed fixes the owner never saw, including a defect
the response's own negative test had shown and written off as noise.

## 7. Publish exactly what was approved

Push the round's commits, when it has any. Then each closing reply in the approved
draft is posted with its resolve. A reply closes, states intent or asks:

- **A reply that closes.** The fix is on the branch (name the commit), or the finding is
  declined with the reason and what was done instead. The thread is **resolved in the
  same pass** — the reply and the resolve are one action, never split across turns.
- **A reply that states intent.** For a major, before its fix: the invariant understood
  and the fix shape intended (`review-discipline.md`) — posted on the draft's approval,
  or, when a question is open, on the approval of the draft redone after the answer
  (step 5). It holds nothing up, and its thread, when it has one, stays open until the
  closing reply.
- **A reply that asks.** A clarification, or a proposal that needs the reviewer's
  agreement before any code is worth writing — posted on the draft's approval. The
  thread **stays open** — and so does the whole PR: nothing else lands until the reviewer
  answers, because the answer can change the approach for every other finding, and fixing
  the "local" ones in the meantime is the patching reflex with a delay. Post every open
  question in the same pass, then stop.

It is rare, and it is a conversation — do not rule it out by treating "resolved in one
pass" as the only shape a reply can take.

```sh
# reply — REST, on the thread's first comment
gh api --method POST repos/<owner>/<repo>/pulls/<n>/comments/<comment databaseId>/replies -f body='…'

# resolve — GraphQL, with the thread id from step 1 (there is no REST equivalent)
gh api graphql -F id=<thread id> -f query='
  mutation($id:ID!) { resolveReviewThread(input:{threadId:$id}) { thread { isResolved } } }'
```

Whatever the reply:

- **Never resolve without a reply, and never resolve a question.** A resolve carries a
  shipped fix or a stated reason — resolving silently is closing the reviewer's mouth, and
  resolving your own open question is answering it for them. A closing reply without its
  resolve leaves the reviewer a thread that looks pending.
- **When the repository requires conversation resolution before merging** — a
  branch-protection setting — a forgotten thread is a *blocked PR*, not a cosmetic gap,
  and the merge button will not tell you which one. Check step 1's `isResolved` flags
  after the pass: every thread with a closing reply reads `true`; every open question
  reads `false`, on purpose, until it is answered and then closed.

## 8. Then re-request the review, when the round has changes to review

`gh pr edit <n> --add-reviewer <login>`, as the last item of the approved draft. A
`CHANGES_REQUESTED` state does not clear when threads resolve; it clears when the
reviewer reviews again. A round that only asked questions does not re-request: the
reviewer owes an answer, not a review.
