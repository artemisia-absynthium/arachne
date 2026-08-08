---
paths:
  - "**/*.swift"
---

# Swift Code Style

## Logging

Never use `print()` in production code. Use `Logger` from `OSLog` everywhere.

Declare all loggers as static properties on a `Logger` extension in a dedicated `Loggers.swift` file, one per subsystem category:

```swift
import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "<your.bundle.id>"
    static let app         = Logger(subsystem: subsystem, category: "App")
    static let networking  = Logger(subsystem: subsystem, category: "Networking")
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
}
```

Call them directly at the use site — no local `logger` constant in individual files:

```swift
Logger.persistence.debug("Opening database at \(path, privacy: .private)")
Logger.app.fault("Something went wrong: \(error)")
```

To add a category, add one line to `Loggers.swift`. Never declare a local `private let logger` in a file.

## File header

Every Swift file starts with:

```swift
//
//  FileName.swift
//  TargetName
//
//  Copyright © <year> <org>. All rights reserved.
//
```

## Imports

Order: system/Apple frameworks first, then internal modules, then local.

```swift
import Foundation
import SwiftUI

import MyModule
import MyOtherModule
```

No blank line within a group; one blank line between groups.

## Naming and structure

- State types: `*State`. Views: `*View`. View models: `*ViewModel`.
- `final class` for state types not intended for subclassing.
- Access control: `private` for implementation details; expose only what callers need.
  Types used across modules are `public`.

## Member ordering

Within every type, members appear in this order — each section separated by a `// MARK: -` comment:

1. Nested types
2. Properties
3. Initializer(s)
4. Protocol conformance methods (one `// MARK: - <ProtocolName>` per conformance)
5. Private helpers

If a file has members scattered outside this order (e.g. nested types mid-file, protocol methods interleaved with helpers), reorder as part of the implementation — not as a separate step.

```swift
final class MyViewModel {

    // MARK: - Nested types

    enum State { case idle, loading, failed(Error) }

    // MARK: - Properties

    private(set) var state: State = .idle

    // MARK: - Initializer

    init(...) { ... }

    // MARK: - SomeProtocol

    func requiredMethod() { ... }

    // MARK: - Private helpers

    private func fetchData() async { ... }
}
```

## Deletion

When removing code, delete it. Never comment it out.

## SwiftLint — enforced rules

| Rule | Action |
|------|--------|
| `force_unwrapping` | Use `guard let` / `if let` — never `!`. Sole exception: `URL(string:)` on a compile-time literal (below) |
| `implicit_return` | Add explicit `return` where required |
| `multiline_arguments` | Each argument on its own line when breaking |
| `multiline_parameters` | Each parameter on its own line when breaking |
| `function_body_length` | Limit is 50 lines. A violation is a code smell — decompose into smaller, focused functions. Do not recover the line count with cosmetic tricks (collapsing lines, dropping trailing commas). |

Run `swiftlint <TargetName>` before submitting any Swift change.

### Sole force-unwrap exception — `URL(string:)` on a compile-time literal

`URL(string: "…")!` is allowed when the argument is a hardcoded string literal. The parse is deterministic and environment-independent: a literal that parses today parses on every device forever, so no runtime failure path exists — an `if let` around it is a dead branch, and demanding one is overengineering. Do not flag existing literal-URL unwrap sites or propose cleanups for them.

The exception dies the instant the argument stops being a literal — interpolation, a parameter, or a config value reinstates the full rule.

```swift
// ✅ — deterministic parse of a literal; no runtime failure path
static let supportURL = URL(string: "https://example.com/support")!

// ❌ — dynamic input; the unwrap can crash at runtime
let url = URL(string: baseURLString + path)!
```

In projects that enable SwiftLint's `force_unwrapping` rule, pair the unwrap with the narrowly-scoped justified suppression from the warning-discipline policy.
