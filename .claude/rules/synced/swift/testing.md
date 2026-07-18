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

## Process-global fixtures — namespace per test, or serialize the suite

Swift Testing runs tests in parallel by default. Any fixture with no per-test instance is
shared by every test in the process, and parallel tests mutating it fail intermittently —
the worst failure mode a suite can have. The tell is not "my tests share a type"; it's
"my tests share something that cannot be instantiated per test": the StoreKit test
environment (every `SKTestSession` controls the *same* environment), the keychain, a real
filesystem path, environment variables, a static cache.

Two remedies, in preference order:

1. **Namespace per test** when the API allows — a `UserDefaults` suite or keychain
   service named with a fresh `UUID`, a per-test temp directory. Parallelism survives and
   ordering coupling becomes impossible.
2. **Serialize the suite** when the fixture is truly singleton:

```swift
@Suite(.serialized)   // SKTestSession: one shared test environment per process
struct StoreKitTests {

    @Test func restoresNothingWhenNoTransactionsExist() async throws {
        let session = try makeSession()
        defer { session.clearTransactions() }   // runs even when an #expect fails
        // ...
    }
}
```

Clean up with `defer` immediately after acquiring the fixture — `#expect` records and
continues on failure, so cleanup at the end of the happy path leaks state into the next
test exactly when something already went wrong.

StoreKitTest gotchas worth knowing before trusting a red test (observed on the iOS 26
simulator): transactions minted by a mid-process `SKTestSession` — via
`buyProduct(productIdentifier:)` or even a real `Product.purchase()` — can fail device
verification (`invalidDeviceVerification`), and `setSimulatedError(_:forAPI:)` can
register without ever firing. Never weaken a production `.verified` check to green such a
test: cover what the platform verifies honestly, extract the unreachable branch into a
pure function and test that, and document the gap.

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
