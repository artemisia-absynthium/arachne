---
name: respond-to-pr-review
description: Act on a received PR review — read every thread from the objects that hold it, decide per finding whether the approach can have the property or only a patch can, show the owner the replies before anything is posted, fix, then reply and resolve in one pass and re-request. Invoke when a review arrives (a CHANGES_REQUESTED state, new review threads, "the PR has been reviewed"), before replying to or fixing anything.
---

# Respond to a PR review

What this prevents: fixing each finding where it sits until the design is a pile of patches,
each locally justified by the one before it; publishing replies the owner never saw; threads
left unresolved, which block the merge under branch protection and read as pending without it.

## 1. Read everything, from the objects that hold it

A review lives in several GitHub objects, and only the inline threads can be resolved:

| Object | Where | Resolvable |
|---|---|---|
| Review body and state (`APPROVED`, `CHANGES_REQUESTED`) | `gh pr view <n> --json reviews` | No — answered by a comment and a re-requested review |
| Inline review threads | GraphQL `pullRequest.reviewThreads` — each with `id`, `isResolved`, `path`, `line`, `comments` | **Yes**, and only through GraphQL |
| Issue comments | `gh pr view <n> --json comments` | No |

Read every one before forming a view. The inline threads are the ones that get lost: they are
not in the review body, and `gh pr view` does not show them.

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

## 2. Decide per finding, one line each

```
<finding> — about this PR? <introduced | touched | no> — <fix the approach | fix in place | decline: why | ask>
```

- **Not about this PR** — the base branch has the same defect and the diff neither introduced
  nor touched it: an observation in the reply, no fix here.
- **Before any fix, ask whether the current approach can have the property at all.** If it
  cannot, the answer is a design change, not a construction that fakes the property: that
  construction is always available and always locally reasonable, which is exactly why it is not
  the default. Several "cannot" on one approach means the approach is dead; the reply says so.
- A reviewer's suggested remedy is one candidate, not an order; the simplest correct one wins.
  **Unsure is a valid answer** and is not resolved by guessing: it becomes a question to the
  reviewer.

**Why:** a first review said an approach preserved order "by luck rather than by construction".
The response added a construction. The second review found the same class of finding again and
again, and each got a patch, until the owner rewrote the feature in an afternoon by replacing the
type — an option available since the first finding and never generated, because every finding had
been read as "add what fixes this".

## 3. Show the owner the replies before anything is posted

One message: per finding its line from step 2 and the reply to post, verbatim; the fixes intended;
the verification to re-run. The owner reads it and says go, or changes it. A bare "respond to the
review" asks for this message, not for its publication. Check in only where different readings
would lead to materially different work; a question the owner already answered is not re-asked.

## 4. Fix locally, then publish what the owner saw

- Fix; re-run the verification named in step 3; squash the round's fix commits (`git-discipline.md`).
- Anything that came out different from what the owner saw — a remedy that changed shape, a
  verification result other than the one expected, a new comment from the reviewer — goes back
  to the owner before publication.
- Push the round's commits when it has any. Then each reply is posted **with its resolve, as one
  action** — never split across turns:

```sh
# reply — REST, on the thread's first comment
gh api --method POST repos/<owner>/<repo>/pulls/<n>/comments/<comment databaseId>/replies -f body='…'

# resolve — GraphQL, with the thread id from step 1 (there is no REST equivalent)
gh api graphql -F id=<thread id> -f query='
  mutation($id:ID!) { resolveReviewThread(input:{threadId:$id}) { thread { isResolved } } }'
```

- A reply **closes** (the fix is on the branch, commit named, or the finding is declined with the
  reason), **states intent** on a major before its fix — the invariant understood and the fix
  shape intended (`review-discipline.md`) — or **asks**. An open question keeps its thread open and
  the whole PR waits for the answer, because the answer can change every other fix; post every
  open question in the same pass, then stop.
- **Never resolve without a reply, and never resolve a question.** Under required conversation
  resolution a forgotten thread is a blocked PR and the merge button will not say which; check
  `isResolved` after the pass.

## 5. Re-request the review when the round changed code

`gh pr edit <n> --add-reviewer <login>`. A `CHANGES_REQUESTED` state clears only when the reviewer
reviews again. A round that only asked questions does not re-request: the reviewer owes an
answer, not a review.
