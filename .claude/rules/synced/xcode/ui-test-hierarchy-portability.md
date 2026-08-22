---
paths:
  - "**/*UITests*/**"
  - "**/*.swift"
---

# UI-Test Hierarchy Portability — One Suite, Every Platform's Tree

A multi-platform SwiftUI app renders one view tree into *different accessibility
hierarchies* per platform, and XCUITest queries written against one of them silently
describe only that platform. The same adaptive shell is a tab bar of `Button`s at
compact width, a sidebar of `OutlineRow`s on macOS, and a Mac-shaped split view with
iOS element types on regular-width iPad. A suite that queries by element type
(`app.buttons`, `app.cells`, `app.tabBars`, `app.staticTexts` + label predicate) is an
iPhone suite that happens to compile everywhere.

## Query by identifier, matched at any element type

Give the views stable `accessibilityIdentifier`s and match them without asserting an
element type — which element type carries the identifier is exactly the thing that
varies per platform:

```swift
// ✅ — finds the element whatever it surfaces as (Button, StaticText, outline row…)
app.descendants(matching: .any).matching(identifier: "item-row").firstMatch

// ❌ — encodes iPhone's rendering; matches nothing on macOS
app.cells.firstMatch
app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Section'")).firstMatch
```

Keep the test-side identifier literals in **one `XCUIApplication` extension file**. The
app-side modifier and the test-side query cannot share a constant across targets, so
greppable, literal-for-literal identical strings are the only drift guard the contract
has — never derive them (`"tab-" + name.lowercased()`), which defeats the grep.

## Known propagation gap: `TabContent.accessibilityIdentifier` on macOS

macOS does **not** propagate `TabContent.accessibilityIdentifier` into the
`.sidebarAdaptable` sidebar (verified against the live hierarchy, 2026-08): the sidebar
entry surfaces as a bare `StaticText` whose *value* — not label — is the tab title, with
no identifier. Section lookups therefore need an identifier-OR-title predicate, and must
be scoped to the window — an app-wide title match can resolve to a menu-bar
`CommandMenu` of the same name, which `firstMatch` may find first:

```swift
// ✅ — window-scoped: menu-bar items are outside windows, sidebar rows inside
func rootSection(_ section: RootSection) -> XCUIElement {
    windows.firstMatch.descendants(matching: .any).matching(
        NSPredicate(format: "identifier == %@ OR label == %@ OR value == %@",
                    section.identifier, section.title, section.title)
    ).firstMatch
}
```

View-level identifiers (list rows, buttons inside content) do surface on macOS — the
gap is specific to tab/sidebar entries.

## Branch on the hierarchy, never on the platform

Where the *interaction* genuinely differs (a pushed detail has a back button; a split
view keeps both panes on screen), branch on what the hierarchy offers, not on
`#if os(...)` — regular-width iPad behaves like Mac with iOS element types, so a
platform check gets it wrong by construction:

```swift
// ✅ — a hittable list row means both panes are visible (no push happened)
if app.itemRow.isHittable {
    // regular width: leave by switching sections
} else {
    // compact: the detail covers the list — a real pop exists
}
```

Two traps this replaces:

- **`navigationBars.buttons.firstMatch` is not a back button.** On iPad, toolbar
  actions land in the navigation bar, so `firstMatch` can be a *destructive action*
  — a test "going back" was actually triggering it. Hittability of the underlying
  list row is the reliable discriminator of push-vs-panes.
- **`XCTSkipUnless` on a hierarchy query is a silent coverage hole.** A skip that
  fires on every run of one platform reports green while covering nothing there.
  Express the equivalent interaction for that layout and hard-assert; reserve
  `#if os(...)` for genuinely absent APIs (`XCUIDevice.press(.home)`).

## Rationale

Every one of these was a shipped bug class: a suite green on iPhone/iPad that failed
4–6 tests on its first-ever macOS run (element-type queries), two tests green-by-skip
on two platforms for months, and a "back" tap that mutated app state on iPad. The
identifier vocabulary fixed all of them without touching app behavior — identifiers
are invisible, unlocalized, and free to ship in every configuration.
