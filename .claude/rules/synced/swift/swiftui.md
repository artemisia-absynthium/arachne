---
paths:
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

When two or more views need the same state object simultaneously, lift it to the DI container (e.g. an `AppState`-equivalent). Holding duplicate `@State` instances gives each view an independent copy with no shared signal between them — mutations in one view are invisible to others.

### @State vs @Bindable for @Observable

- `@State var model = MyModel()` — the **owner**. SwiftUI allocates the instance; any initialiser argument is used only on the first render and ignored thereafter. Use only in the view that creates and manages the object.
- `@Bindable var model: MyModel` — the **receiver**. The instance is created elsewhere and passed in; `@Bindable` provides `$model.property` bindings without allocating a new instance.

Using `@State var model: MyModel` on a property that receives a passed-in `@Observable` object is a silent bug: SwiftUI ignores the passed value and creates its own instance, so the child view never observes the caller's state.

## Previews

Previews must not hit the network or any real persistent store. Provide in-memory
test doubles or static fixture data.