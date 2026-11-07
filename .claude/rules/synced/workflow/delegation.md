---
description: Builds and tests always go to an agent; each delegate gets the cheapest model that fits its task.
---

# Delegation

When to use a subagent, a fork or another session is the main thread's judgment, using the
harness's own guidance. This rule adds only the cases that judgment gets wrong, and the model
each delegate runs on.

## Always delegated, however small

- **Builds and test runs**, every one, including the single "does it compile" inside an edit
  loop. The delegate returns the diagnostics as `path:line: message` and the run's verdict.
  Each build looks too small to hand off; the loop of them is what fills the context and forces
  compactions.
- **Once a check is delegated, the main thread does not run it too** until the result is back:
  a second run of the same check reports on code that has moved.
- Log, result-bundle and dependency audits, and documentation lookups whose sources are many pages.

## Fork or fresh agent

A fork inherits the whole conversation and runs on the session's model; a fresh agent knows
only its brief and can run on a cheaper model. Fork when the context a brief would lose
matters to the result; start fresh when a brief carries it. **A review is never a fork:** an
inherited conversation anchors the reviewer on the author's reasoning.

## Mechanical multi-file changes

A rename, an API adoption, a refactor with a stated rule: an agent in its own worktree, whose
diff is read before it is merged.

## Model per delegate

| Model | Task shape | Examples |
|---|---|---|
| `haiku` | Mechanical: known target, known output, no judgment between; `effort: low` | run a command and return its verdict; a lookup in one named document |
| `sonnet` | Standard work from a complete brief | explorers; builds and test runs; a specified change; tests to a stated spec |
| `opus` | Judgment under a lens, or design-bearing work | reviewers; a design alternative; a diagnosis with an unknown cause |
| `fable` | The hardest judgment, where an `opus` return failed on judgment or the owner asks | a contested architectural decision; a diagnosis that two `opus` passes could not settle |

- Every spawn names its model, by alias.
- Between two tiers, take the lower one and tighten the brief. A tier is raised when a return
  failed on judgment, never on missing information: that is a brief defect.
- `fable` may bill to usage credits; where an advisor model is configured, consulting it at a
  decision point is usually cheaper than delegating the whole task to `fable`.
