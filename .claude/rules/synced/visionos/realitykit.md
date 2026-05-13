---
description: visionOS / RealityKit — RealityView lifecycle, makeContent, attachments, entity rules, concurrency
globs:
  - "**/*.swift"
---

# visionOS & RealityKit

## Naming

- Entity types: `*Entity`. State types: `*State`. Views: `*View`.

## Imports

`RealityKit` goes in the system/Apple group, before internal modules:

```swift
import RealityKit
import SwiftUI

import MyModule
```

## RealityView pattern

```swift
RealityView { content, attachments in
    await state.load()                          // always first — makeContent runs once
    content.add(state.root.entity)
    if let ui = attachments.entity(for: UIEntity.AttachmentID.controls) {
        state.root.controlsAnchor.addChild(ui)
    }
    // Other async tasks which need to run after view loaded must be detached: content will not be shown until this returns
    Task { await showMyAnimations() }
} attachments: {
    Attachment(id: UIEntity.AttachmentID.controls) {
        ControlsView()
    }
}
```

## makeContent runs exactly once

The `makeContent` closure executes a single time. Consequences:
- Call `await state.load()` synchronously at the top — do not defer or lazy-load
- Any entity referenced via `attachments.entity(for:)` must already exist at this point
- Do not schedule state changes inside `makeContent` that depend on future updates

## Entity rules

- **BillboardComponent**: do not parent an entity under a `BillboardComponent` ancestor if the child needs independent orientation — reparent to the root entity instead
- **z-offset**: keep ≤ 0.01 m from the SwiftUI attachment plane. Parallax error grows as `z_offset / anchor_depth` — visible at arm's length with offsets above 1 cm
- **Animations**: use `slide(to:)` with explicit world coordinates. `slide(by: Transform(translation:))` initialises scale to `[1,1,1]` and adds it to existing scale — a bug
- **Transform is not Sendable**: do not capture `Transform` in `withTaskGroup` / `addTask` closures. Use `SIMD3<Float>` to pass positions across task boundaries

## Environment and state injection

- Root views receive state via `@Environment(StateType.self)` — pass from the scene with `.environment(state)`
- Mark views `@MainActor` when they access app or feature state
- Async closures inside views: `Task { @MainActor [weak self] in ... }`

## Previews

Previews must supply all required environments:

```swift
#Preview {
    MyFeatureView()
        .environment(MyFeatureState())
        .environment(AppState.shared)
}
```
