# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and test

This is a Swift Package — no `.xcodeproj`. All tooling goes through SPM or `xcodebuild`.

```bash
# Build
swift build

# Run all tests (macOS)
swift test

# Run tests on a simulator platform (use -skipPackagePluginValidation to suppress SwiftLint plugin prompt)
xcodebuild test \
  -scheme Arachne \
  -destination "platform=iOS Simulator,id=$(xcrun simctl list devices available | grep iPhone | head -1 | awk -F'[()]' '{print $(NF-3)}')" \
  -skipPackagePluginValidation

# Run a single test by name
swift test --filter "ArachneTests/<TestFunctionName>"
```

CI runs tests on macOS, iOS, tvOS, watchOS, and visionOS simulators. See `.github/workflows/swift.yml`.

## Architecture

Arachne is a zero-dependency networking library built on `URLSession` and async/await. The design is intentionally thin — no Combine, no third-party dependencies, no code generation.

### Core pattern

Callers define their API as an `enum` conforming to `ArachneService`, then instantiate `ArachneProvider<MyService>` to execute requests. The provider is a `Sendable` value type; all task methods are `nonisolated`.

```
ArachneService (protocol)
  └─ defines: baseUrl, path, method, body, headers, queryStringItems,
              validCodes, expectedMimeType, timeoutInterval

ArachneProvider<T: ArachneService> (struct, Sendable)
  ├─ data(_:)          → (Data, URLResponse)
  ├─ bytes(_:)         → (URLSession.AsyncBytes, URLResponse)
  ├─ download(_:)      → (URL, URLResponse)              [simple]
  ├─ download(_:sessionConfiguration:didWriteData:...)   [progress + cancellable]
  ├─ download(_:withResumeData:...)                      [resume from partial data]
  ├─ upload(_:from:)   → (Data, URLResponse)
  ├─ upload(_:fromFile:) → (Data, URLResponse)
  └─ urlRequest(for:)  → URLRequest                      [public, for escape-hatch use]
```

Provider is configured via a fluent builder — these return a new value, they don't mutate:
```swift
let provider = ArachneProvider<MyService>()
    .with(plugins: [MyLoggingPlugin()])
    .with(requestModifier: { endpoint, request in ... })
```

### Response validation

`handleResponse` is called on every successful task. It checks:
1. `validCodes` — throws `ARError.unacceptableStatusCode` on mismatch
2. `expectedMimeType` — throws `ARError.unexpectedMimeType` on mismatch

Both errors carry the full `HTTPURLResponse` and an `AROutput` (`.data`, `.url`, or `.bytes`) so callers can inspect partial results on failure.

### Plugin system

`ArachnePlugin` (protocol, `Sendable`) gets called at three points:
- `handle(request:)` — before the request is sent
- `handle(response:output:)` — before a successful result is returned
- `handle(error:request:output:)` — before an error is thrown

### Resumable downloads

The two progress-based `download` overloads use `ArachneDownloadDelegate` (a `URLSessionDownloadDelegate` subclass). They return a `URLSessionDownloadTask` the caller must retain for cancellation. Resume data comes from `error.downloadResumeData` (extension on `Error` in `ARError.swift`).

## Testing conventions

Tests use **Swift Testing** (`@Suite`, `@Test`, `#expect`, `#require`) — not XCTest.

Network calls are intercepted by `StubURLProtocol` (a `URLProtocol` subclass). Tests configure an ephemeral `URLSessionConfiguration` with `StubURLProtocol` registered, then pass that session to the provider. `StubURLProtocol.stubExchanges` maps `URLRequest` → `StubResponse` using a `Set<StubNetworkExchange>`.

Test service definitions live in `Tests/ArachneTests/Model/` (`MyService`, `MyServiceWithDefaults`).

## Platforms

macOS 12+, iOS 15+, tvOS 15+, watchOS 8+, visionOS 2+, macCatalyst 15+. Swift 6 (`swift-tools-version: 6.1`). The library has no platform-specific code — all public API is available on all supported platforms.

## SwiftLint

SwiftLint runs as a build tool plugin. Fix all violations before committing. Do not suppress rules globally in `.swiftlint.yml` — use inline `// swiftlint:disable:next` with a justification comment.
