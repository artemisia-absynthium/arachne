---
name: respond-to-pr-review
description: The procedure for acting on a received PR review — for every finding, decide whether the current approach can have the property at all before writing any fix; re-enter the four planning questions on any finding it cannot; then reply to and resolve every inline thread through the API that actually resolves it. Invoke the moment a review arrives (a CHANGES_REQUESTED state, new review threads, "the PR has been reviewed"), before replying to or fixing anything.
---

# Respond to a PR review

Two failures this exists to prevent. The first: fixing each finding where it sits until
the design is a pile of patches, each one locally justified by the one before it. The
second: leaving threads unresolved, which blocks the merge under branch protection and,
without it, reads to the reviewer as work still pending.

## 1. Read everything, from the objects that actually hold it

A review is three different things on GitHub, and only one of them can be resolved:

| Object | Where | Resolvable |
|---|---|---|
| Review body and state (`APPROVED`, `CHANGES_REQUESTED`) | `gh pr view <n> --json reviews` | No — answered by a comment and a re-requested review |
| Inline review threads | GraphQL `pullRequest.reviewThreads` — each with `id`, `isResolved`, `path`, `line`, `comments` | **Yes**, and only through GraphQL |
| Issue comments | `gh pr view <n> --json comments` | No |

Read all three before forming a view. The inline threads are the ones that get lost:
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

## 2. Before any fix: can the approach have this property by construction?

For every finding, one written line before touching code:

```
<finding> — can the current approach have this property by construction? <yes | no> — <the argument>
```

- **Yes, the code just fails to do it** → a local fix.
- **No** → the approach is dead *for that property*. It does not get a construction bolted
  on that fakes the property; that construction is always available and always locally
  reasonable, which is exactly why it must not be the default. Go back to the four
  questions at the top of `planning-discipline`. The answer to the review is then a
  design, not a list of fixes, and the reply says so.
- **Several "no"s** → the approach is dead, full stop, and the review has told you so
  four times in a row. Read it that way.

A reviewer's *suggested* remedy is one candidate, not a requirement — the four questions
apply to it too. "Do X, or scope down and open a follow-up" is two options, not an order.

The argument is what makes this step honest rather than a table to fill in: "yes,
independently scheduled tasks preserve call order because…" cannot be finished, and a
line that cannot be finished is a "no".

**Unsure is a valid answer**, and it is not resolved by guessing. It becomes a question
to the reviewer in step 3, and the PR waits for the answer.

**Why:** a first review said an approach preserved order "by luck rather than by
construction". The response added a construction that preserved it. The second review
found the same class of finding — the approach cannot observe X by construction — four
separate times, and the response was nine patches. The owner then rewrote the feature in
an afternoon by replacing the type, an option that had been available since the first
finding and was never generated, because every finding had been read as "add what fixes
this" and none as "this cannot be fixed from here".

## 3. Reply, then resolve — every thread, through its own API

Every inline thread gets a reply, and a reply is one of two things:

- **A reply that closes.** The fix is on the branch (name the commit), or the finding is
  declined with the reason and what was done instead. The thread is **resolved in the
  same pass** — the reply and the resolve are one action, never split across turns.
- **A reply that asks.** A clarification, or a proposal that needs the reviewer's
  agreement before any code is worth writing. The thread **stays open** — and so does the
  whole PR: nothing else lands until the reviewer answers, because the answer can change
  the approach for every other finding, and fixing the "local" ones in the meantime is
  the patching reflex with a delay. Post every open question in the same pass, then stop.

It is rare, and it is a conversation — do not rule it out by treating "resolved in one
pass" as the only shape a reply can take.

```sh
# reply — REST, on the thread's first comment
gh api --method POST repos/<owner>/<repo>/pulls/<n>/comments/<comment databaseId>/replies -f body='…'

# resolve — GraphQL, with the thread id from step 1 (there is no REST equivalent)
gh api graphql -F id=<thread id> -f query='
  mutation($id:ID!) { resolveReviewThread(input:{threadId:$id}) { thread { isResolved } } }'
```

Two rules:

- **Never resolve without a reply, and never resolve a question.** A resolve carries a
  shipped fix or a stated reason — resolving silently is closing the reviewer's mouth, and
  resolving your own open question is answering it for them. A closing reply without its
  resolve leaves the reviewer a thread that looks pending.
- **When the repository requires conversation resolution before merging** — a
  branch-protection setting — a forgotten thread is a *blocked PR*, not a cosmetic gap,
  and the merge button will not tell you which one. Check step 1's `isResolved` flags
  after the pass: every thread whose finding is on the branch reads `true`; every open
  question reads `false`, on purpose, until it is answered and then closed.

## 4. Then re-request the review

`gh pr edit <n> --add-reviewer <login>`. A `CHANGES_REQUESTED` state does not clear when
threads resolve; it clears when the reviewer reviews again.
