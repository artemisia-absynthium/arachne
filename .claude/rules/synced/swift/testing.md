---
paths:
  - "**/*Tests*/**/*.swift"
  - "**/*Test.swift"
---

# Swift Testing

This project uses the **Swift Testing** framework. Do not use XCTest patterns.

## Structure

```swift
import Testing

@Suite("ItemListViewModel")
struct ItemListViewModelTests {

    @Test("loads item descriptor from JSON")
    func loadsDescriptor() async throws {
        let viewModel = ItemListViewModel()
        let object = try #require(await viewModel.load())
        #expect(object.property == "expected")
    }
}
```

- `@Suite` groups related tests. No `XCTestCase` subclassing.
- `@Test` marks individual test functions.
- Test functions are plain `func`, not prefixed with `test`.

## Assertions

| Assertion | Use |
|-----------|-----|
| `#expect(condition)` | Standard assertion — test continues on failure |
| `#expect(throws: ErrorType.self) { }` | Error assertion |
| `#require(optional)` | Unwraps optional — aborts test on nil |
| `#require(throws: ...) { }` | Requires a throw — aborts if none |

Use `#require` for preconditions whose failure makes the rest of the test meaningless.
Use `#expect` for all other assertions so failures accumulate.

## `#expect(try …)` inside throwing closures

`#expect(try …)` whose only throwing expressions live inside the macro arguments can fail to compile with "Errors thrown from here are not handled" (reported in the macro expansion) when nested inside a throwing closure — e.g. a database `write`/`read` block. The failure is shape-sensitive: visually identical code sometimes compiles. Don't fight it; use the two patterns that always work:

```swift
// ✅ (a) hoist the throwing reads into a binding, assert afterwards
let counts = try db.read { d in
    (items: try Item.fetchCount(d), orders: try Order.fetchCount(d))
}
#expect(counts.items == 9)
#expect(counts.orders == 3)

// ✅ (b) for throw assertions, wrap the entire closure call
#expect(throws: DatabaseError.self) {
    try db.write { d in try d.execute(sql: "DELETE FROM item WHERE id = 'i1'") }
}

// ❌ — may fail to compile depending on surrounding shape
try db.write { d in
    #expect(throws: DatabaseError.self) { try d.execute(sql: "…") }
    #expect(try Item.fetchCount(d) == 9)
}
```

Both patterns also read better: the transaction does the work, the assertions judge it.

## StoreKit tests

StoreKit suites using `SKTestSession` must be marked `.serialized` — `SKTestSession` is not safe to run in parallel:

```swift
@Suite(.serialized)
struct StoreKitTests { ... }
```

## Test doubles

Do not introduce a protocol whose sole purpose is to allow mocking in tests (the protocol-for-testability anti-pattern). This adds indirection without load-bearing benefit and contradicts Apple's own guidance (reiterated at WWDC sessions). Use concrete injection instead:

| Dependency | Testable seam |
|------------|---------------|
| Networking / `URLSession` | `URLSession(configuration:)` with a registered `URLProtocol` subclass |
| `UserDefaults` | `UserDefaults(suiteName: UUID().uuidString)!` — isolated suite per test, no cleanup needed |
| File I/O | Inject a `URL` or path pointing to a temp directory (`FileManager.default.temporaryDirectory`) |
| `@MainActor` class needing overrides | Subclass and override the specific methods under test |

```swift
// Good — isolated suite, no cross-test contamination, no protocol invented
private func isolatedDefaults() -> UserDefaults {
    UserDefaults(suiteName: UUID().uuidString)!
}

@Test("setting store persists id")
func settingStorePersistsId() {
    let defaults = isolatedDefaults()
    let state = StoreState(network: network, userDefaults: defaults)
    state.currentStore = makeStore(id: "42")
    #expect(defaults.selectedStoreId == "42")
}
```

For networking, register a `URLProtocol` subclass on the session configuration so the real `URLSession` code path executes with controlled responses — this catches serialisation bugs that protocol mocks silently hide.

## UI tests

UI tests use XCTest (via `XCUIApplication`). Swift Testing does not support UI test targets.
Only unit and integration test targets use `@Test` / `@Suite`.
