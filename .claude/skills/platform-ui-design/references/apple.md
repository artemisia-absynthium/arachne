# Apple platforms — iOS, iPadOS, macOS, watchOS, tvOS, visionOS

One guideline covers every Apple platform: the Human Interface Guidelines. Its pages carry their
own "Platform considerations" sections; read the one for the target platform.

## Source order

1. **Xcode MCP `DocumentationSearch`**, when the session has the Xcode MCP. It indexes the full
   HIG text (results under `/design/Human-Interface-Guidelines/…`) beside the framework references,
   so one query returns the guideline and the API that implements it.
2. **Fetching** `developer.apple.com/design/human-interface-guidelines/<page>`. The pages render
   with JavaScript: a fetch commonly returns only the page title.
3. **The browser**, reading only, for a page the fetch returned empty.

## Xcode's built-in agent skills — the current API, from Apple

Export them once per machine, then load the one that answers the question:

```
xcrun agent skills export ~/.agents/skills
```

- `swiftui-whats-new-<release>` — new APIs and behaviour of the current release (toolbars, bars,
  presentation). Read it before naming a mechanism: it supersedes recall.
- `swiftui-specialist` — best practices and performance.
- `uikit-app-modernization` — for UIKit surfaces.
- `device-interaction` — drives a simulator for step 9 (taps, screenshots, the UI hierarchy).

## What the designer most often needs

- **Two layers.** Liquid Glass is the functional layer for controls and navigation (bars, sidebars,
  floating controls); the content layer uses standard materials and never glass. Text-heavy
  components use the regular glass variant. A custom element names its layer.
- **Sidebars and bars float.** On current releases sidebars, toolbars and tab bars float above the
  content, which extends beneath them. A strip laid across the whole window above them cuts them;
  status that must stay visible belongs in a bar or in the detail column.
- **A custom bar is a safe-area bar.** Content placed beside a view as a bar insets the safe area
  (every scroll view stops short of it) and extends the scroll edge effect under it; no per-view
  offsets.
- **Toolbar placements carry meaning.** The trailing edge holds items that must stay available;
  the status placement is informational only and holds no actions; one prominent action per bar.
- **Mac apps are native, not phone apps on a desktop:** menus, keyboard shortcuts, windows.

## Verify (step 9)

- iOS and iPadOS: the preview, or a simulator screenshot at the target device and orientation.
- visionOS: a simulator screenshot; previews may not render through tooling.
- A preview renders on the canvas's own device; when the size matters, use the simulator.
