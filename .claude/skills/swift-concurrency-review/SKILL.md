---
name: swift-concurrency-review
description: Dedicated Swift concurrency review pass over a diff or branch — actor reentrancy across await, CheckedContinuation discipline, terminal-state races, cancellation propagation, callback ordering, @unchecked Sendable justification. Invoke for the concurrency pass of a PR review, or after touching actors, continuations, async sequences, or background callbacks.
---

# Swift Concurrency Review

The Swift-concrete checklist for a dedicated concurrency pass over a branch diff. Each item
is a bug class that has shipped past general review; the general design pass
(`design-review-lens`) does not cover them.

- **Actor reentrancy**: any state read before an `await` and used after it must be
  re-validated — the actor processed other work during the suspension. A guard checked
  before `await` proves nothing after it.
- **`CheckedContinuation` discipline**: resumed exactly once on every path (including
  error paths); never leaked (an abandoned continuation suspends its task forever); never
  assumed cancellation-aware — `Task.cancel()` does NOT resume a checked continuation, the
  code owning it must resolve it on cancel explicitly.
- **Terminal-state races**: periodic observation/progress loops must be stopped *before*
  a terminal state is written, or a late tick clobbers it.
- **Cancellation propagation**: long async sequences check `Task.checkCancellation()` at
  the top and between phases; work that must not outlive its owner is not `Task.detached`.
  Never swallow `CancellationError` with `try?` around `Task.sleep` — catch it and stop.
- **Callback ordering**: delegate callbacks arriving on framework queues that hop to
  `@MainActor` via `Task` lose ordering guarantees — two hops can land inverted. Any logic
  that depends on arrival order needs a single serialization point.
- **`@unchecked Sendable`**: justified only by all-immutable storage or documented internal
  synchronization (e.g. an owned actor/lock), stated in a comment on the type. Mutable
  `var` state under `@unchecked Sendable` is a finding, always.
- **Isolation suppression**: `@preconcurrency` or `nonisolated` added to silence a compiler
  error is a finding until the real isolation crossing is named and shown to be safe.
