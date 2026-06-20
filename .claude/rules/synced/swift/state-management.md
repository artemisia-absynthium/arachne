---
paths:
  - "**/*ViewModel*.swift"
  - "**/*Model*.swift"
  - "**/*Repository*.swift"
  - "**/*State*.swift"
---

# Swift Async State Management

Two shapes model async data on an `@Observable @MainActor` view model. Pick by the **data source** and the **states the screen actually has** — don't reach for one reflexively.

## Choosing the shape

**Per-screen `State` enum — default for SwiftUI view models.** Declare an enum with exactly the cases that screen has and `switch` on it exhaustively in the view.

```swift
enum State {
    case loading
    case loaded([Item])
    case empty            // domain state — distinct from loaded([])
    case failed(Error)
}
```

Prefer it when:

- The source is a **reactive stream** that pushes new values over time — a database change-observation API, a WebSocket/SSE feed, or any `AsyncSequence` consumed with `for try await`. The stream re-emits a fresh `.loaded` on every change, so there is no manual refresh gap and no need for a stale-carrying loading case.
- The screen has **domain-specific states** — `empty`, `unavailable` (the entity was deleted), and so on — that deserve their own compiler-checked arm instead of being smuggled into `loaded([])` / `loaded(nil)`.
- You want concrete associated values and an exhaustive `switch` (illegal states unrepresentable).

For a **manual re-fetch that should keep showing stale data**, add the case explicitly rather than reaching for `Loadable`:

```swift
case refreshing([Item])   // current items stay on screen while a re-fetch is in flight
// or fold it into loaded: case loaded([Item], isRefreshing: Bool)
```

**`Loadable<T>` — for imperative, request/response (one-shot) fetches.** Use it when the source is pull-based (you call it and it answers once), the screen is the plain loading/loaded/failed shape, and the built-in "not yet requested" and "stale-while-refreshing" behaviour — plus uniformity across many similar screens — are worth more than per-screen tailoring.

> Network code is **not** inherently one shape. A plain REST `GET` is request/response — `Loadable<T>` fits. A WebSocket, SSE feed, or polling loop wrapped as an `AsyncSequence` is a stream — the `State` enum fits.

**Either way, render by switching on the cases.** Do not render from a derived optional `value` while separately observing a loading flag — that split is what forces the `onChange(of: isLoading())` workaround noted below.

## The Loadable<T> pattern

Use `Loadable<T>` to represent the full lifecycle of an imperative async fetch. Define it once per project:

```swift
enum Loadable<T> {
    case notRequested          // no fetch initiated yet
    case isLoading(last: T?)   // in progress; last carries stale data for display while refreshing
    case loaded(T)             // succeeded
    case failed(Error)         // failed; surface error or offer retry
}
```

Useful computed helpers:

```swift
extension Loadable {
    var value: T? {
        switch self {
        case let .loaded(v): return v
        case let .isLoading(last): return last
        default: return nil
        }
    }
    var error: Error? {
        if case let .failed(e) = self { return e }
        return nil
    }
    func isLoading() -> Bool {
        if case .isLoading = self { return true }
        return false
    }
}
```

Store `Loadable<T>` on `@Observable @MainActor` state classes, not on views. The standard fetch pattern:

```swift
func load() async {
    data = .isLoading(last: data.value)
    do {
        data = .loaded(try await fetch())
    } catch {
        data = .failed(error)
    }
}
```

## Rules

**Switch on the full state, not on derived optionals.** A nil selection or missing value while `Loadable` is `.isLoading` or `.notRequested` is not an error — it means the data hasn't arrived yet. Only infer an error from `.failed` or from `.loaded` when the value is genuinely absent.

**If you render from `Loadable.value`, observe `isLoading()` alongside it.** When a load fails, the derived optional value stays `nil` — no change fires — so an `onChange(of: loadable.isLoading())` observer is needed to catch the `true → false` transition and react to `.failed`. Switching directly on the `Loadable` cases (with a `.failed` arm) avoids this entirely.
