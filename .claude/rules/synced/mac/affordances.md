---
description: Mac app affordances — menus, keyboard shortcuts, windows, drag-and-drop, native chrome
globs:
  - "**/*.swift"
---

# Mac Affordances

Real Mac apps built with SwiftUI must include:

- **Menu bar commands** for primary actions (`Commands { ... }` on the `Scene`).
- **Multiple-window scene support** where the app has document-like content.
- **Keyboard shortcuts** on every primary action (`keyboardShortcut(_:)` is platform-aware).
- **Drag-and-drop** support for content types the app owns.
- **Context menus** (right-click) for secondary actions.
- **Native window chrome** — no custom title bars, no Electron-style decoration.

Do not ship a Mac target via Catalyst if native AppKit/SwiftUI is feasible. Catalyst is
acceptable only when a project explicitly decides the fidelity trade-off is worth it.

The Mac target is a first-class deliverable — not an iPhone app with Mac as an afterthought.
