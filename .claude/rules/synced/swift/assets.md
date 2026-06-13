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

## Color assets — use ColorResource, not strings

Xcode generates a type-safe `ColorResource` for every color set in an asset catalog. Same rationale as images: the string-name initializer cannot detect a renamed or missing asset until the wrong colour ships in the UI. The `ColorResource`-based initializer turns the same mistake into a compile error.

Available iOS 17+ / macOS 14+ / tvOS 17+ / watchOS 10+ / visionOS 1+.

**SwiftUI**

```swift
// ✅
.tint(Color(.brandPrimary))
.background(Color(.surface))
.foregroundStyle(Color(.textPrimary))

// ❌ — typo or rename fails silently
Color("brandPrimary")
```

When targeting older OSes, keep the string init but add a `// TODO: upgrade to Color(ColorResource) when minimum deployment raises to iOS 17 / macOS 14` comment so the spot is easy to find.
