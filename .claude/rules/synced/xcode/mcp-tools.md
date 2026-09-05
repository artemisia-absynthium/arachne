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
(`XcodeRefreshCodeIssuesInFile`, `XcodeListNavigatorIssues`, `XcodeGrep`,
`DocumentationSearch`), never through the `swift-lsp` plugin / `LSP` tool. Standalone
`sourcekit-lsp` has no Xcode-project backend: without an `xcode-build-server` bridge it has
no compile flags for Xcode targets and produces hallucinated findings (e.g. "missing import"
for a symbol that exists in another target), and even bridged its index is build-pinned
while Xcode's hosted SourceKit indexes live. Keep `swift-lsp` disabled on these projects.

## Gotchas

- **Tab identifier**: every Xcode MCP tool requires a `tabIdentifier`. Discover it with
  `XcodeListWindows` at session start — it depends on window open order; never hardcode it.
- `XcodeMakeDir` fails with an unknown-project-structure error unless `XcodeLS` has run
  earlier in the same session.
- **Git staging**: `XcodeUpdate` and `XcodeWrite` do NOT auto-stage their changes — `git add`
  the modified files explicitly before committing. `XcodeRM` stages deletions automatically;
  the asymmetry is easy to miss.
- **`BuildProject` builds Xcode's active run destination**, whatever it currently is. With a physical device selected in Xcode's UI, the build compiles the `iphoneos` slice and reports success while the simulator product goes stale — a later `simctl install` then ships an old binary, and runtime verification silently exercises yesterday's code. Before trusting a simulator install after an MCP build, confirm the product is fresh (file timestamp on the app binary is the reliable check; `strings`-grepping for a new literal is not — Swift literals don't always survive as contiguous C strings). If the destination can't be confirmed in Xcode, build the simulator slice explicitly via CLI: `xcodebuild -destination 'platform=iOS Simulator,name=...' build` — this is a tool-capability gap, not an MCP defect, so the fallback is legitimate.
