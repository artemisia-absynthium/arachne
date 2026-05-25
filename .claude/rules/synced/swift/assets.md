---
paths:
  - "**/*.swift"
---

# Asset Loading

## Image assets — use ImageResource, not strings

Xcode generates a type-safe `ImageResource` for every image in an asset catalog. Use it instead of string-based lookups in all new code. String names can silently return `nil` at runtime; `ImageResource`-based APIs are non-optional and catch missing assets at compile time.

**SwiftUI**

```swift
// ✅
Image(.myIcon)

// ❌
Image("myIcon")
```

**UIKit** (`UIImage(resource:)` requires iOS 17+)

```swift
// ✅
UIImage(resource: .myIcon)

// ❌
UIImage(named: "myIcon")
```

The `UIImage(resource:)` initialiser is non-optional — no `guard let` or `!` needed, and no silent failure if the asset name is mistyped or later renamed.
