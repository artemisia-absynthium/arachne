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
