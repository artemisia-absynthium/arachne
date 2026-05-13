---
description: Swift Testing framework — @Test, @Suite, #expect, #require. Not XCTest.
globs:
  - "**/*Tests*/**/*.swift"
  - "**/*Test.swift"
---

# Swift Testing

This project uses the **Swift Testing** framework. Do not use XCTest patterns.

## Structure

```swift
import Testing

@Suite("ProductsViewModel")
struct ProductsViewModelTests {

    @Test("loads product descriptor from JSON")
    func loadsDescriptor() async throws {
        let viewModel = ProductsViewModel()
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

## UI tests

UI tests use XCTest (via `XCUIApplication`). Swift Testing does not support UI test targets.
Only unit and integration test targets use `@Test` / `@Suite`.
