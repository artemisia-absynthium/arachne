---
paths:
  - "**/*.swift"
---

# Liquid Glass (iOS 26+)

## Two origins of glass — only one is yours

Glass you request — `.glassEffect(_:in:)`, `.buttonStyle(.glass)` — is yours: you pick
the shape and can group and morph it (`GlassEffectContainer` + `glassEffectID`). Glass
the system applies — nav-bar/toolbar items, tab bars — is bar decoration: the framework
owns its geometry. `buttonBorderShape(_:)` only shapes chrome that a *bordered* button
style renders; a `.plain` button inside a toolbar gives the bar nothing to read, so the
bar wraps the item's laid-out bounds in its default capsule regardless (verified on
device).

## Suppress, then own

To control a bar item's glass shape, remove the system's drawing and draw your own:

```swift
ToolbarItem(placement: .topBarTrailing) {
    MyCircularButton()
        .glassEffect(.regular, in: .circle)   // yours: shape is guaranteed
}
.sharedBackgroundVisibility(.hidden)          // suppresses the bar's capsule
```

This is the same structural move as `scrollContentBackground(.hidden)` before painting
a custom `List` background: when a framework draws a decoration that ignores your
preference modifiers, look for the visibility modifier that removes the drawing
entirely — the API surface almost always ships that pair together.

## Verification ladder

Canvas previews composite bar-owned glass unfaithfully (observed: a preview rendered a
circle where the device rendered a capsule). For material shape and grouping decisions:
preview is a smoke test, the simulator is evidence, the device is the verdict. Never
close a Liquid Glass ticket on a preview screenshot.
