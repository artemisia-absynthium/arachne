---
description: Build and test through the Xcode MCP on the project's GUI workspace (a headless one has no simulators), switching scheme and destination right before every run, because both slip silently and a build reports success for whichever is active
---

# Xcode MCP — Building and Testing

Build, test, preview, and diagnostics go through the Xcode MCP tools; `xcodebuild` is the
fallback only when the MCP is genuinely unavailable (see the tool-fallback rule). File operations
through the MCP are `mcp-tools.md`.

## Gotchas

- **Workspace approval**: the server refuses every tool until the workspace has been opened
  through the MCP with the absolute `.xcworkspace`/`.xcodeproj` path — that call is what prompts
  the user to approve the agent for the project (once per project). Which identifier the other
  tools then take, and under which parameter name, is in their schemas — read them, never a
  rule file: the server changes them between Xcode releases and a copy here rots.
- **A workspace opened through the MCP is headless, and a headless workspace has no
  simulators.** Measured on Xcode 27.2, with the GUI running: the workspace that call returns
  lists only generic and physical-device destinations, the destination switch refuses every
  simulator, and a test run fails with "Tests must be run on a concrete device". Meanwhile
  `xcodebuild -showdestinations` on the same project lists the simulators as compatible, so the
  project and its runtimes are fine. Open the project in the Xcode GUI too (`open -a Xcode
  <path>`): the workspace list then holds a second entry for the same path, its destinations
  include the simulators, and the scheme switch, destination switch and test runs all work there.
  Target that entry, matched by path when several copies of one project are open (worktrees).
  The empty list looks like a missing runtime or a broken project, and reaching for the CLI hides
  the real cause.
- **No scheme parameter — the active scheme slips.** `BuildProject` and `RunAllTests` build the
  *active scheme*, and there is no way to name one per call. Xcode resets the active scheme to the
  first scheme alphabetically (often a package dependency's scheme) whenever the shared
  `.xcscheme` files are rewritten on disk — observed after `git rebase` and `git checkout` touching
  them. Symptom: a "successful" one-second build whose log first line names the wrong
  scheme and that compiled none of the edited files. Switch with `XcodeSwitchScheme` right before
  every build or test run, then confirm the build log's first line names the intended scheme.
  Switching also restores that scheme's remembered run destination, so re-check the destination
  too (the `BuildProject` destination gotcha). For what rewrites `.xcscheme` files from the other
  direction — GUI edits clobbering hand edits — see `schemes.md`.
- **`BuildProject` builds Xcode's active run destination**, whatever it currently is. With a physical device selected in Xcode's UI, the build compiles the `iphoneos` slice and reports success while the simulator product goes stale — a later `simctl install` then ships an old binary, and runtime verification silently exercises yesterday's code. Before trusting a simulator install after an MCP build, confirm the product is fresh (file timestamp on the app binary is the reliable check; `strings`-grepping for a new literal is not — Swift literals don't always survive as contiguous C strings). If the destination can't be confirmed in Xcode even on the project's GUI workspace (a headless one never lists simulators — see the headless-workspace gotcha), build the simulator slice explicitly via CLI, with `-scheme` and a destination resolved to a UDID as `test-destinations.md` prescribes — this is a tool-capability gap, not an MCP defect, so the fallback is legitimate.
