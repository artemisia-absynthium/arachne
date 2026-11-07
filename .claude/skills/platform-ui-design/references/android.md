# Android — phones, tablets, foldables, Wear OS, TV, XR

The guideline is Material Design in its current version. Read the version from
`m3.material.io`; never assume it.

## Source order

1. **The `android` CLI's documentation search**: `android docs search "<keywords>"`, then
   `android docs fetch <url>`. It searches an offline knowledge base of developer.android.com,
   including Android's own design guides (layout and navigation patterns) and the Compose Material
   components. It does not include Material's own component specifications.
2. **Fetching `m3.material.io`** for component specifications: anatomy, measurements, usage, and
   the do and don't cases.
3. **The browser**, reading only, for a page the fetch returned empty.

## Android's agent skills — the current API, from Google

Install them with `android skills`, then load the one that answers the question:

- `adaptive` — window size classes, multi-pane layouts, navigation rails and bars by width.
- `navigation-3` — scenes: list-detail, supporting pane, dialogs, bottom sheets.
- `edge-to-edge` — insets, system bars, content behind them.
- `styles` — the Compose styles API for component theming.
- Form-factor skills where they apply (Wear, TV, XR, glasses).

## What the designer most often needs

- **Navigation follows the window size class**: a navigation bar when compact, a rail when medium,
  a drawer or rail when expanded. One layout per class, not one per device.
- **Content is drawn edge to edge**, behind the system bars, with insets applied, never padded by
  guesswork.
- **Surfaces and elevation are tonal**, from the theme's colour roles; status uses the components
  built for it (snackbars, banners, progress indicators), not custom strips.

## Verify (step 9)

An emulator screenshot through the `android` CLI, at the target window size class and orientation.
