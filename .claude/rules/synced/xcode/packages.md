---
description: Package management — SPM only; no CocoaPods or Carthage
globs:
  - "**/*.swift"
  - "**/Package.swift"
  - "**/*.xcodeproj/**"
---

# Package Management

Use Swift Package Manager exclusively. Do not introduce CocoaPods or Carthage.

- Add dependencies via SPM in Xcode or `Package.swift`.
- Pin dependencies to specific versions or commits — do not track `main` or `master` directly.
- A dependency bump is an explicit choice; it should appear as a deliberate diff in `Package.resolved`.
