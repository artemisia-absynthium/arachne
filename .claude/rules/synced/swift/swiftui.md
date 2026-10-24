---
paths:
  - "**/*.swift"
---

# SwiftUI Conventions

## App entry point — the SwiftUI `App` life cycle, only

Every app starts from `@main struct …: App` and its scenes — throwaway probes and sample projects
included. Never `UIApplicationMain`, a `@main` `UIApplicationDelegate`, or an app delegate that
creates its own `UIWindow`.

```swift
// ✅
@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: MyAppDelegate   // only for a callback below
    var body: some Scene {
        WindowGroup { RootView() }
    }
}

// ❌ — no scene life cycle: the app fails to launch on the 27 SDKs
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        // …
        return true
    }
}
```

A `UIApplicationDelegate` survives only behind `@UIApplicationDelegateAdaptor`
(`@NSApplicationDelegateAdaptor` on macOS), for app-level callbacks SwiftUI has no equivalent for
(e.g. the remote-notification device token). Foreground and background transitions are read from
`scenePhase`, never from the delegate.

Rationale: the app-delegate life cycle is no longer merely superseded — it does not launch. Apple:
"Beginning in iOS 27, iPadOS 27, Mac Catalyst 27, tvOS 27, and visionOS 27, apps built with the
latest SDK must adopt the scene-based life cycle or they fail to launch" (UIKit, *Transitioning to
the UIKit scene-based life cycle*). Observed on an iOS 27.0 simulator: the process traps
(`EXC_BREAKPOINT` in UIKitCore's `_UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption`)
while UIKit creates its first scene — a crash report, not a log line, so nothing hints at the cause.

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

Give previewable views their own file: a `#Preview` next to a private view struct in a
file whose primary type is a `ViewModifier` can fail the preview thunk with "ambiguous
use of '__designTimeSelection'". Moving the view and its previews to their own file
resolves it — and matches the one-view-per-file rule anyway.

## Modal dismissal

Every dismissable modal closes with the system circular X, placed leading:

```swift
.toolbar {
    ToolbarItem(placement: .topBarLeading) {
        Button(role: .close) { dismiss() }
    }
}
```

The system supplies the glyph and the accessibility label — add neither a custom label
nor a text button ("Done", "Close"). One dismissal affordance everywhere beats
per-sheet invention. Sanctioned exceptions: persuasion surfaces where the exit copy is
load-bearing (e.g. a paywall's "continue for free"), and modals that are deliberately
non-dismissable.

## Web content opens in-app

Web destinations present inside the app — a sheet hosting `WebView` (WebKit for
SwiftUI, iOS 26+/macOS 26+) or an `SFSafariViewController` wrapper on older targets —
never a `Link` that bounces the user out to Safari. Leaving the app mid-flow is a
drop-off point, and coming back is on the user.

Reserve external Safari for destinations where leaving genuinely serves the user (for
example, content whose login/session state lives in the user's browser, or a link into
another app). When in doubt, stay in-app. Ship the error state with the web sheet: a
failed load shows an explicit unavailable state, never a silent blank page.

## List backgrounds — strip the system fill before painting a custom one

A `List` (or `Form`, `ScrollView`) paints the standard system grouped background on top of whatever `.background(...)` you set. The custom background never reaches the screen.

To use a custom background under a scrollable view, combine **two** modifiers — the order doesn't matter, but skipping the first is the most common mistake:

```swift
// ✅
List {
    // rows
}
.scrollContentBackground(.hidden)        // strip the system fill
.background(Color(.myBackground))        // now the custom paint shows

// ❌ — system fill masks the custom background; List still looks default
List {
    // rows
}
.background(Color(.myBackground))
```

`scrollContentBackground(_:)` is iOS 16+ / iPadOS 16+ / macOS 13+ / visionOS 1+ / watchOS 9+ (no tvOS). On macOS 15+ it also controls the seamless window/titlebar appearance.

Applies to `List`, `Form`, and `ScrollView`. `Form` and `List` paint the system fill by default; `ScrollView` does not, so it normally needs no modifier — but if you opt it into the seamless macOS chrome via `.scrollContentBackground(.visible)`, the symmetric rule applies in reverse.
