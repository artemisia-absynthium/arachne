---
paths:
  - "**/*View*.swift"
  - "**/*Screen*.swift"
---

# Firebase Analytics — Screen View Tracking

When `FirebaseAnalytics` is a dependency in a SwiftUI project, every navigable **screen** must log a `screen_view` event.

## What counts as a screen

- App root views
- `NavigationLink` destinations
- `.navigationDestination` targets
- `.sheet` and `.fullScreenCover` content views

## What does NOT log screen views

- Reusable components embedded inside screens
- Generic container/wrapper views (e.g. a `BottomSheetContent` wrapper)
- `ViewModifier`-presented overlays

## Implementation pattern

Add `.analyticsScreen(name:)` on the **outermost view** in each screen's `body`:

```swift
import FirebaseAnalytics
import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack { ... }
            .analyticsScreen(name: AnalyticsScreenSettings)
    }
}
```

For views that branch on `if #available`, wrap the branch in a `Group` and apply common modifiers — including `.analyticsScreen` — to the `Group`:

```swift
var body: some View {
    Group {
        if #available(iOS 16, *) {
            content
                .scrollDismissesKeyboard(.immediately)
        } else {
            content
        }
    }
    .analyticsScreen(name: AnalyticsScreenFoo)
}
```

## Screen name constants

Define all screen name strings as named constants in one place (e.g. a `StringExtension.swift` or `AnalyticsConstants.swift` file), following the project's analytics naming convention. Use snake_case string values.

Example convention:

```swift
// prefix: AnalyticsAppScreen*, values: snake_case
let AnalyticsAppScreenSettings    = "settings"
let AnalyticsAppScreenChooseStore = "choose_store"
```

Never scatter raw string literals across screen files.

## Import requirement

Every screen file that uses `.analyticsScreen()` must explicitly `import FirebaseAnalytics`.