---
description: SwiftUI conventions — view structure, adaptive layouts, state ownership, previews
globs:
  - "**/*.swift"
---

# SwiftUI Conventions

## View structure

- One view per file. Large views split into private subviews in the same file.
- No singletons for app state — inject via initializers or SwiftUI Environment.

## Adaptive layouts

Target multiple form factors from a single view. Use `NavigationSplitView`, size classes,
and `@Environment(\.horizontalSizeClass)`. Where platforms genuinely differ, express it in
adaptive container views — not duplicated screens.

## State ownership

Views own ephemeral UI state. Persistent or shared state lives in `@Observable @MainActor`
view models. See `concurrency.md` for the full pattern.

## Previews

Previews must not hit the network or any real persistent store. Provide in-memory
test doubles or static fixture data.
