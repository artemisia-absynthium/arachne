---
description: Every UI surface follows the conventions of the platform it runs on — native apps their vendor's guideline, the web its own conventions — and never borrows another platform's idioms
---

# Platform UI conventions

Every UI surface follows the conventions of the platform it runs on. The axis is native versus web,
not phone versus desktop: a desktop app built with the platform's own toolkit is native and follows
its vendor's guideline as fully as a phone app does.

- **Native apps** follow the vendor's design guideline in its current version: Apple's Human
  Interface Guidelines for every Apple platform, Material Design for Android. A guideline is read
  before designing, never recalled — both change every year.
- **Web** has no vendor guideline. Its authorities, in order: the project's own design system,
  WCAG for accessibility, and the web platform's semantics and behaviour (real links, the browser's
  back button, URLs that reflect state, keyboard focus, layouts that adapt to any width).
- **A native platform with no reference** in the `platform-ui-design` skill (a desktop OS, a
  console's system UI) still follows its vendor's own guideline, read from the vendor before
  designing. That platform's first design adds its reference to the skill.

## Never transplant one platform's idioms onto another

The tell is the same in every direction: the surface looks borrowed. The lists are the common
cases, not the whole ban.

- **Web into native:** a full-width notification strip above the whole window; toasts stacking in
  a corner; a hamburger menu where the platform uses a sidebar or tab bar; a modal closed by an X
  in the top-right corner; affordances that appear only on hover; underlined text links used as
  buttons; pagination controls instead of scrolling; breadcrumbs; a cookie-banner-style footer
  bar; a card with a shadow as the default container; fixed pixel widths instead of the platform's
  size classes.
- **Native into web:** an imitation phone tab bar or back chevron; fake system sheets, alerts or
  pickers; gestures with no visible control; a platform's typeface or system colours copied to
  look native.
- **Between native platforms:** one platform's components and chrome on another. A cross-platform
  product shares content and behaviour, never chrome.

## Hybrid shells

An app that hosts web content inside a native shell (a desktop wrapper, a web view inside a native
screen): the shell's chrome — menus, windows, toolbars, system dialogs — follows the native platform;
the web content inside follows the web.

## Scope

Games are out of scope: their HUDs, menus and in-world UI follow the game's own art direction and
genre conventions. The platform surfaces a game presents — purchase sheets, platform sign-in,
permission prompts, share sheets — are the system's and stay as the system draws them.

## Deviations

A departure from the guideline is stated with its reason and accepted by the owner, the same shape
as a workaround (`terminology.md`). "It looks fine" and "the design file shows it" are not reasons.

Designing a new UI surface, or changing where one sits: invoke the `platform-ui-design` skill.

**Why:** a full-width banner stacked above a floating sidebar was designed by reasoning about the
code alone; it cut the sidebar's panel in half and read as a web page inside a native app. The
guideline that would have caught it was one search away.
