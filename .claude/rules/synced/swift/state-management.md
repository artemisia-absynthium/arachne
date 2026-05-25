---
paths:
  - "**/*ViewModel*.swift"
  - "**/*Model*.swift"
  - "**/*Repository*.swift"
  - "**/*State*.swift"
---

# Swift Async State Management

## The Loadable<T> pattern

Use `Loadable<T>` to represent the full lifecycle of an async data fetch. Define it once per project:

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

**In SwiftUI, observe `isLoading()` alongside optional values.** When a load fails, the optional value stays `nil` — no change fires. An `onChange(of: loadable.isLoading())` observer is needed to catch the `true → false` transition and react to `.failed`.

