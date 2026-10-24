---
description: The Swift lines of the write-time checklist — structured concurrency keeps the caller's order and teardown, test-only state lives under #if DEBUG, try? only where the error is expected or out of our control and cannot reach the user
paths:
  - "**/*.swift"
---

# Write it right the first time — Swift

The language-agnostic lines are `workflow/write-time-checklist.md`; these are the ones reviewers
keep finding in Swift specifically.

- **Structured concurrency keeps the order.** An unstructured `Task` carries its isolation
  annotation; when a `Task` replaces an awaited call, the teardown and ordering the caller relied
  on are kept explicitly. The rest is `swift-concurrency-review`.
- **Test-only state lives under `#if DEBUG`.** Counters, last-seen values and injection points for
  tests never ship in the release type.
- **`try?` is a decision, not a shortcut.** It discards the error, so it appears only where the
  failure cannot reach the user and a log line would say nothing — expected, or outside our
  control — with the comment beside it saying which; otherwise `do`/`catch` handles, logs or
  rethrows. `try!` is never: crashable code.
