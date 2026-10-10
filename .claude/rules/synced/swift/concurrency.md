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

## Pick the primitive by the job, not by its age

The rule is against **superseded** shapes — an older primitive used where the modern one gives the
same guarantees — not against every older API. By job:

- **An async result** (a load, a request, a one-shot answer) → `async/await`. Completion handlers,
  `Result` callbacks and `DispatchQueue.async` hops for these are superseded; they survive only at
  a framework boundary with no async form, bridged once with a continuation.
- **State a view renders** → `@Observable @MainActor`. `ObservableObject` / `@Published` are
  superseded entirely.
- **A synchronous notification of a transition** — "run this in the same turn the phase changed,
  before anything else on the actor" — is neither state management nor async work. A plain closure
  or a returned value is the right seam. Observation is an invalidation signal (willSet semantics,
  once per registration, coalesced) and `Observations {}` delivers asynchronously; neither can
  promise same-turn ordering. Say in one line why the timing matters.
- **Values over time** → `AsyncSequence` / `AsyncStream`. Combine stays where it is the better fit
  — reactive KVO (`publisher(for:)`), multi-publisher merging, bridging a delegate into a stream —
  with a one-line comment on why.
- **Framework-mandated delegates and callbacks** (`URLSession`, ARKit, system broadcasts) are
  neither superseded nor optional; forward `Sendable` values out of them into your own primitive,
  on the queue the framework gives you.

The test: could this be written with the modern primitive *without losing a guarantee* —
ordering, same-turn timing, back-pressure, a framework contract? If yes, the older shape is
superseded here. If a guarantee would be lost, the older shape is the right tool: name the
guarantee in a comment where the rule would otherwise read as violated.

## MainActor discipline

All work that reads or mutates `@Observable` state or touches the UI runs on `@MainActor`; from a
background context, hop explicitly rather than relying on inference.

## Async closures and capture lists

Async closures that capture `self` always use `[weak self]`. Always annotate `@MainActor` explicitly — do not rely on inference from the enclosing method, which can silently break if isolation changes:

```swift
Task { @MainActor [weak self] in
    guard let self else { return }
    self.result = await fetch()
}
```

### A stored callback that starts a `Task`: the capture list goes on the outer closure

When the `Task` is created inside an escaping closure that something stores — a back-navigation
action, a completion handler — `[weak self]` belongs on that outer closure. On the inner `Task` it
protects nothing: to form the weak copy, the outer closure has to capture `self` strongly, and it
holds that reference for as long as it is stored. The compiler reports it: *"'weak' ownership of
capture 'self' differs from implicitly-captured strong reference in outer scope"*.

```swift
// ❌ the stored closure captures self strongly to hand it to the Task
child = ChildState(onBack: {
    Task { @MainActor [weak self] in await self?.showHome() }
})

// ✅ the stored closure holds self weakly; the Task captures that weak reference
child = ChildState(onBack: { [weak self] in
    Task { @MainActor in await self?.showHome() }
})
```

The rule: a capture list sits on the outermost closure that escapes, because that is where the
reference is held.

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

## Review pass

For a dedicated concurrency review of a diff (reentrancy, continuations, cancellation, ordering,
`@unchecked Sendable`), invoke the `swift-concurrency-review` skill.
