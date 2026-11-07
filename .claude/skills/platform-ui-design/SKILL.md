---
name: platform-ui-design
description: Design a UI surface the way a designer and a developer would together — a designer agent proposes options grounded in the platform's current guideline (Apple HIG, Material, or the web's own conventions), the main thread annotates what each costs in the codebase, the owner chooses, the result is rendered and checked. Invoke before building a new screen, banner, bar, panel or control, or before moving where one sits.
---

# Platform UI design — designer proposes, developer annotates, owner chooses

The rule is `workflow/platform-ui.md`. This is how to meet it: two roles, as on a real team.

- **The designer knows the guideline** — layers, components, the platform's own precedents. A
  developer designing alone builds what is easy to wire and calls it fine.
- **The developer knows what a design costs here** — the mechanism, the invariants it touches, the
  requirements it would break. A designer alone proposes the option that looks cleanest and cannot
  be built.

## The roles

- **Designer: a subagent on `opus`** (design-bearing work). It gets a brief, not the codebase, and
  proposes **without mechanism**: keeping it out of the code keeps it from designing what is easy
  to build.
- **Developer: the main thread, by default.** It already holds the code context, the invariants
  and the task's charter; a developer subagent would receive them as a brief that drops the one
  fact that matters. A separate developer agent is the exception, when the main thread does not
  hold the context either.
- **Owner: chooses** between annotated options. Neither role picks for them.

The designer proposes and never decides: every decision stays with the main thread and the owner. What the designer adds is options the main thread would not have
generated.

## The workflow

1. **Brief the designer.** The surface's purpose and what it must show; the platforms and the
   target device class with its size and orientation; the requirements it must keep (always
   visible, not dismissable, per-device…); the reference for each platform below; the transplant
   lists from the rule. No file paths, no types.
2. **The designer frames the surface:** its purpose, the layer each element lives in, and the
   platform's own precedent — which system app does something similar, or "none found".
3. **The designer reads the guideline**, current version, through the source order in the
   platform's reference, and cites each section it relied on. Recall is not a source.
4. **The designer proposes options**, simplest first, preferring system components and standard
   placements. A custom component names the guideline gap it fills. Each option is checked against
   the transplant lists; a match is redesigned, never justified.
5. **The designer returns** each option as a mockup in the platform's frame (its real size in
   points or dp, the target orientation) with its layer and cited sections. Where the session
   offers a Design artifact type (a design canvas), the mockups go there; otherwise inline.
6. **The developer annotates** every option: the mechanism (the platform API that implements it,
   checked against current documentation), its cost and risk in this codebase, and every
   requirement it would break. One option is recommended, with the reason.
7. **One revision at most.** An option the annotation rules out may go back to the designer once,
   with the finding stated as a property. A second round means the brief was wrong: fix the brief.
8. **The owner chooses.** A deviation from the guideline is presented as such, with its reason.
9. **Render and verify** before the owner judges it: the platform's preview, simulator or emulator
   screenshot, or browser, as the platform's reference says — at the target size and orientation.
   A design is never presented as done from code alone.

## References — read the one for the platform being designed

- `references/apple.md` — every Apple platform.
- `references/android.md` — Android: phones, tablets, foldables, Wear, TV, XR.
- `references/web.md` — the web, and the web content inside a hybrid shell.

A platform with no reference follows the rule's bullet for platforms without one: read the vendor's guideline, then add
the reference here.
