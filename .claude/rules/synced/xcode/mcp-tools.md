---
paths:
  - "**/*.swift"
  - "**/*.xcodeproj/**"
---

# Xcode MCP Tools

Build, test, preview, and diagnostics go through the Xcode MCP tools; `xcodebuild` is the
fallback only when the MCP is genuinely unavailable (see the tool-fallback rule). Plain
filesystem tools are fine for reading and editing existing Swift files — the operations
below are where the MCP is required.

## Adding, moving, deleting files

A project can mix synchronized folders and legacy groups — check with `XcodeLS` or inspect
`project.pbxproj` for `PBXFileSystemSynchronizedRootGroup` vs `PBXGroup`.

- **Legacy groups (`PBXGroup`)**: create files with `XcodeWrite` — it adds the
  `PBXFileReference` and compile-sources entry a filesystem write would omit; move and
  delete with `XcodeMV` / `XcodeRM` for the same reason.
- **Synchronized folders**: write with the filesystem tool directly into the synced
  directory — `XcodeWrite` places the file at the project root and omits it from the
  compile sources phase.

## Code intelligence

On Xcode projects, query diagnostics and symbols through Xcode MCP
(`XcodeRefreshCodeIssuesInFile`, `XcodeGrep`, and on Xcode 26 also `XcodeListNavigatorIssues`
and `DocumentationSearch` — Xcode 27's server no longer exposes those two), never through the
`swift-lsp` plugin / `LSP` tool. Standalone
`sourcekit-lsp` has no Xcode-project backend: without an `xcode-build-server` bridge it has
no compile flags for Xcode targets and produces hallucinated findings (e.g. "missing import"
for a symbol that exists in another target), and even bridged its index is build-pinned
while Xcode's hosted SourceKit indexes live. Keep `swift-lsp` disabled on these projects.

## Gotchas

- **Workspace approval and identifier (Xcode 27+)**: the server refuses every tool until
  `XcodeOpenWorkspace` has been called with the absolute `.xcworkspace`/`.xcodeproj` path — that
  call is what prompts the user to approve the agent for the project (once per project) and it
  returns a `workspaceIdentifier`. Pass that value as `workspaceIdentifier` to every other tool,
  including the tools whose schema still advertises only `tabIdentifier` (`BuildProject`,
  `GetBuildLog`, `XcodeListSchemes`, `XcodeListRunDestinations`, `GetTargetBuildSettings`): the
  schema is stale, the server rejects `tabIdentifier` and names the open workspaces in the error.
  `XcodeListWindows` is gone; `xcrun mcp-server status` shows approval state and open workspaces.
  Never hardcode the identifier — it is minted per open. (Xcode 26: every tool took a
  `tabIdentifier`, discovered with `XcodeListWindows`, dependent on window open order.)
- **No scheme parameter — the active scheme slips.** `BuildProject` and `RunAllTests` build the
  *active scheme*, and there is no way to name one per call. Xcode resets the active scheme to the
  first scheme alphabetically (often a package dependency's scheme) whenever the shared
  `.xcscheme` files are rewritten on disk — observed after `git rebase` and `git checkout` touching
  them. Symptom: a "successful" one-second build whose log first line names the wrong
  scheme and that compiled none of the edited files. Switch with `XcodeSwitchScheme` right before
  every build or test run, then confirm the build log's first line names the intended scheme.
  Switching also restores that scheme's remembered run destination, so re-check the destination
  too (next bullet). For what rewrites `.xcscheme` files from the other direction — GUI edits
  clobbering hand edits — see `schemes.md`.
- `XcodeMakeDir` fails with an unknown-project-structure error unless `XcodeLS` has run
  earlier in the same session.
- **Git staging**: `XcodeUpdate` and `XcodeWrite` do NOT auto-stage their changes — `git add`
  the modified files explicitly before committing. `XcodeRM` stages deletions automatically;
  the asymmetry is easy to miss.
- **`BuildProject` builds Xcode's active run destination**, whatever it currently is. With a physical device selected in Xcode's UI, the build compiles the `iphoneos` slice and reports success while the simulator product goes stale — a later `simctl install` then ships an old binary, and runtime verification silently exercises yesterday's code. Before trusting a simulator install after an MCP build, confirm the product is fresh (file timestamp on the app binary is the reliable check; `strings`-grepping for a new literal is not — Swift literals don't always survive as contiguous C strings). If the destination can't be confirmed in Xcode, build the simulator slice explicitly via CLI: `xcodebuild -destination 'platform=iOS Simulator,name=...' build` — this is a tool-capability gap, not an MCP defect, so the fallback is legitimate.
