---
description: Side-work a task admits but does not need — a pre-existing warning, debt on the path — is priced when admitted and re-priced at every divergence; over the price it is backed out to a dedicated change, never fixed forward
---

# Side-work carries a kill criterion

Some rules put work into a task that the task did not ask for: a zero-warnings policy has
pre-existing warnings fixed before the requested work starts, and debt on the path gets
admitted "because it is a small change". Admitting it is right. Admitting it without a price is
how a small, well-defined feature ends up rewriting code it never needed to touch. This rule is
the missing half of the admitting ones: the admission is a decision, and every decision under
`plan-execution.md` is re-examined at each divergence.

Build errors are not side-work. A build that does not pass blocks verification itself, so an
error the task did not introduce is fixed or reported as a blocker (`build-discipline.md`); it
is never backed out.

## Price it when you admit it

The moment side-work enters the task, write its kill criterion next to it in the task plan, as
the cost you expect, in units a later event can violate: commits, review findings, files outside
the feature's own list.

```
Side-work: fix the four capture warnings in the navigation closures.
Kill criterion: one commit, zero review findings, no file outside the feature's list.
```

"Small" is not a price. A criterion is something a later event can violate.

## Re-price at every divergence, against the admission price

Every divergence that touches the side-work — a review finding on it, a fix it needs, a design
question it raises — is compared with the criterion written at admission, never with the
previous step. Step to step, every fix looks like one more local fix; against the admission
price, a second review finding on side-work is already over. Cumulative cost is invisible unless
something written holds it.

## Over the price, back it out — never fix forward

When the criterion is violated, the default proposal is that the side-work leaves the task: its
commits are dropped from the branch and its files return to the base. It is a proposal, like
every change that follows a divergence (`plan-execution.md`), and the outcome is reported the
way `terminology.md` reports a fix that cannot be made correctly: "cannot be fixed within this
task's price". The task plan drops the side-work entry; the feature's plan is unchanged, because
nothing about the feature was wrong — only the add-on's cost estimate was. What was backed out
is recorded where dedicated work will find it: the `TECH-DEBT` annotation of `code-style.md` at
the site, and the project plan's decision log when it outlives the task.

Fixing forward is the construction `plan-execution.md` warns about, always available and always
locally justified: each fix is judged against the last fix, and the chain never ends on its own.

Signals that the price is exceeded whatever the criterion says:

- a fix to the side-work needs a fix of its own — a warning fix that introduces a leak has
  already cost more than the warning;
- a review round whose blocking finding lands on a file the feature does not require.

Rationale: a small, well-defined feature admitted a four-line warning fix as a small change. The
fix reworked the closures the warnings sat in; the next review found the rework had removed a
teardown, which led to a teardown design for a module the feature never touched, which pulled a
rule rewrite along. Every step was a locally correct answer to the previous one, and nothing in
the loop compared the running cost with the price the fix was admitted at. The branch was
rebuilt from the base with only the feature — two commits, the original plan, unchanged — which
is what the kill criterion produces at the first exceeded price instead of the last.
