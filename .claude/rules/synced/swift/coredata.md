---
paths:
  - "**/*.swift"
---

# Core Data

## Context queue confinement — every access goes through `perform`

`NSManagedObjectContext` is queue-confined: `viewContext` is bound to the main queue, background contexts to their own private queue. Every operation on a context — fetch, count, insert, delete, **save** — must run inside that context's `perform { }` (callback or `async` overload) or `performAndWait { }`.

The trap under Swift concurrency: a nonisolated `async` method runs on the global concurrency executor, **not** the main thread — even when every caller is `@MainActor`. So "this method only touches `viewContext`, and the app drives it from the UI" is exactly the reasoning that breaks. Isolation belongs to the method, not the caller.

Off-queue access is undefined behavior that rarely crashes at the violation site. It corrupts the context's internal state and detonates later in unrelated-looking ways — `EXC_BAD_ACCESS` inside `-[NSManagedObjectContext save:]`, `NSInvalidArgumentException: -[__NSCFSet addObject:]: attempt to insert nil`, intermittent save errors — which crash reporters group under misleading symptoms far from the offending line.

```swift
// ✅ — confined; safe from any executor
func trimHistory() async {
    await container.viewContext.perform {
        let context = self.container.viewContext
        // fetch / delete / save on `context`
    }
}

// ❌ — nonisolated async: runs on a background executor and
// touches the main-queue-confined viewContext directly
func trimHistory() async {
    let stale = try? container.viewContext.fetch(request)
    stale?.forEach { container.viewContext.delete($0) }
    try? container.viewContext.save()
}
```

Apple's documented exception — code already on the main thread may use a main-queue context directly — is safe only where isolation is compiler-enforced (`@MainActor`). In nonisolated or `Sendable` types, wrap every access in `perform`; do not rely on what the current call sites happen to do.

## Catch violations in Debug

Add the launch argument `-com.apple.CoreData.ConcurrencyDebug 1` to Debug schemes. It asserts at the violation site instead of letting corruption propagate to a misleading crash in production.
