---
description: One architect thread, delegated parts — what is delegated (output-heavy commands, mechanical multi-file changes), what never is, and the brief and return contract every delegation states
---

# Delegation — one architect thread, delegated parts

The main thread holds the whole picture and makes every design decision. Work that floods
context or is mechanical is delegated with a brief and a return contract, and every return is
read against the charter before it is accepted. This rule is the standing authorization to use
subagents for the cases below; a deterministic workflow (fan-out and verify) runs only when the
owner asks for one in words or invokes a skill that calls it.

## Context hygiene — the rule behind the rules

Raw tool output never lands in the main thread when a conclusion would do. A compaction is a
symptom: output that belonged in an agent was read in the main thread. Target per task: zero.

## Triggers — keyed on events, not on judgment

- **Output-heavy commands** — builds, test runs, log and result-bundle parsing, documentation
  and SDK verification, dependency audits → a fresh agent with an exact brief and return
  contract. It returns verdicts — the test-count check green or shrunk per suite, the build
  warning-free — diagnostics as `path:line: message`, and citations; never totals. A verdict
  lives in the conversation and leaves it nowhere: not a PR body, a commit message, a review or
  a document. The main thread never reads a build log.
- **Mechanical multi-file changes** — renames, API adoption, a refactor with a stated rule → an
  agent that inherits the full context, in a worktree. The main thread reviews the diff against
  the charter and the tests; it does not produce the diff.
- **A design note is drafted** → the four questions in `planning-discipline`, answered in the
  main thread before any lens is opened. A per-lens fan-out is available when the owner asks
  for it, not a default: it evaluates the candidate that was generated and cannot supply the
  one that was not.
- **Any unplanned event** → a divergence (`plan-execution.md`): a diagnosis and a proposed
  change; no delegation and no fix before the diagnosis exists.

## What stays in the main thread

Design-bearing code, invariant enforcement points, anything whose correctness depends on
holding several concerns at once. Delegating these moves the whole picture to nowhere.

## Brief and return contract — every delegation states both

```
Task: <one sentence>. Charter lines in force: <copied, not referenced>.
Acceptance: <the lens or skill by name, the rules in force, the tests that must pass, the
invariants touched>.
Return: <exact shape — e.g. the test-count check's verdict per suite; every diagnostic as
path:line: message; nothing else>. Do not return: <logs, prose, file dumps>.
Model: <per role — review-lenses.md for reviewers, planning-discipline for explorers>.
```

An agent's result is evidence, not truth: the diff or the verdicts are read against the charter
the way a colleague's claim of "clean" would be. Every brief to a coding agent names the rules
in force as acceptance criteria and carries the charter lines it must keep true; every return is
read against them (`charter.md`).
