---
paths:
  - "**/*.swift"
---

# Swift Concurrency

## ViewModels and state

All ViewModels and state classes must be `@Observable @MainActor`:

```swift
@Observable
@MainActor
final class MyViewModel {
    ...
}
```

Never use `ObservableObject` / `@Published`. Never use Combine or completion-handler callbacks for
state management or concurrency — use `@Observable` and async/await instead.

Combine is acceptable where it genuinely fits and async/await would be more verbose: reactive KVO
observation (e.g. `UserDefaults.publisher(for:)`), multi-publisher merging, or bridging legacy
delegate patterns into a stream. If you reach for Combine, add a one-line comment explaining why
async/await is the worse fit in that specific case.

## MainActor discipline

All work that reads or mutates `@Observable` state or touches the UI must run on `@MainActor`.
If you are on a background context and need to update state, hop explicitly:

```swift
await MainActor.run { self.isLoading = false }
// or
Task { @MainActor in self.isLoading = false }
```

## Async closures and capture lists

Async closures that capture `self` always use `[weak self]`. Always annotate `@MainActor` explicitly — do not rely on inference from the enclosing method, which can silently break if isolation changes:

```swift
Task { @MainActor [weak self] in
    guard let self else { return }
    self.result = await fetch()
}
```

Back-navigation and completion callbacks follow the same pattern.

## Structured concurrency

Prefer structured concurrency (`async let`, `withTaskGroup`) over unstructured `Task { }` where possible.
Only use `Task.detached` when you explicitly need to escape the current actor — justify it in a comment.

Do not spin up `Task { }` inside a view body for anything other than brief fire-and-forget UI feedback
(e.g. triggering a haptic, dismissing a sheet after a delay). Any work with side-effects or meaningful
state changes belongs in a view model method, called from `.task { }` or a button action.

## Swift 6 actor isolation

Do not add `@preconcurrency` or `nonisolated` to silence compiler errors without understanding the isolation boundary. Both suppress checks that exist to prevent data races — find and fix the real crossing instead.

## Inter-component communication

Do not use `NotificationCenter` for in-app events. It bypasses type safety, couples unrelated components through a global name-based bus, and works against Swift 6's data-race model.

Prefer in order of fit:
- **Direct `async throws` call** — when the caller already holds a reference to the callee
- **`@Observable` property** — when the receiver needs to observe state it can already access
- **Typed `PassthroughSubject<T, Never>`** — when one-to-many broadcast is genuinely needed (e.g. bridging a delegate callback to multiple subscribers)

`NotificationCenter` is only acceptable for framework-mandated system broadcasts (`EAAccessory`, `UIApplication`, `UIDevice`, etc.) that have no Swift alternative.

## Task.sleep API

Use the `Duration`-based overload — never the legacy nanoseconds form:

```swift
// ✅
try await Task.sleep(for: .seconds(1.5))
try await Task.sleep(for: .milliseconds(500))

// ❌ — legacy API, predates Swift 5.7's Clock-based sleep
try await Task.sleep(nanoseconds: 1_500_000_000)
```

The nanoseconds form is easy to reach for from training data but has no place in modern Swift Concurrency code. The `Duration`-based form is readable, unit-safe, and mockable via the `Clock` protocol.

## Concurrency review lens (pre-PR gate, pass 4)

The Swift-concrete checklist for the workflow `pr-review-gate.md` concurrency pass. Each
item is a bug class that has shipped past general review:

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
- **Callback ordering**: delegate callbacks arriving on framework queues that hop to
  `@MainActor` via `Task` lose ordering guarantees — two hops can land inverted. Any logic
  that depends on arrival order needs a single serialization point.
- **`@unchecked Sendable`**: justified only by all-immutable storage or documented internal
  synchronization (e.g. an owned actor/lock), stated in a comment on the type. Mutable
  `var` state under `@unchecked Sendable` is a finding, always.
