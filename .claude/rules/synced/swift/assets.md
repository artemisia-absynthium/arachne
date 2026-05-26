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

For UIKit (`UIImage(resource:)`), see `ios/assets.md`.
