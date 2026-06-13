---
paths:
  - "**/*.swift"
  - "**/*.xcodeproj/**"
---

# Xcode MCP Tools

Prefer Xcode MCP tools over filesystem equivalents for all operations inside an Xcode project. They handle both synchronized folders (`PBXFileSystemSynchronizedRootGroup`) and legacy groups (`PBXGroup`) correctly, and avoid SourceKit false-positive diagnostics that fire when the filesystem `Read`/`Edit` tools touch Swift files.

## File operations

| Task | Use | Not |
|------|-----|-----|
| Read a source file | `mcp__xcode__XcodeRead` | `Read` |
| Edit a source file | `mcp__xcode__XcodeUpdate` | `Edit` |
| Create a new source file | `mcp__xcode__XcodeWrite` | `Write` |
| List directory contents | `mcp__xcode__XcodeLS` | `ls` / `Bash(ls)` |
| Create a new directory/group | `mcp__xcode__XcodeMakeDir` | `Bash(mkdir)` |

## File operations (continued)

| Task | Use |
|------|-----|
| Delete a file | `mcp__xcode__XcodeRM` |
| Move / rename a file | `mcp__xcode__XcodeMV` |
| Search file contents | `mcp__xcode__XcodeGrep` |
| Search by filename pattern | `mcp__xcode__XcodeGlob` |

## Build, test, and preview

| Task | Use |
|------|-----|
| Build the project | `mcp__xcode__BuildProject` |
| Run all tests | `mcp__xcode__RunAllTests` |
| Run specific tests | `mcp__xcode__RunSomeTests` |
| List available tests | `mcp__xcode__GetTestList` |
| Read the build log | `mcp__xcode__GetBuildLog` |
| Render a SwiftUI preview | `mcp__xcode__RenderPreview` |
| Run a code snippet | `mcp__xcode__ExecuteSnippet` |
| Search Apple docs | `mcp__xcode__DocumentationSearch` |

## Code intelligence

When Xcode is the IDE for the project — whether an `.xcodeproj`/`.xcworkspace` or an SPM package opened in Xcode — query code intelligence (diagnostics, symbol navigation, documentation) through Xcode MCP, not through the standalone `sourcekit-lsp` exposed by the `LSP` tool / `swift-lsp` Claude Code plugin.

Why:

- `sourcekit-lsp` has no native Xcode-project backend. Its `defaultWorkspaceType` is `swiftPM`, `compilationDatabase`, or `buildServer` only. Without `xcode-build-server` writing a `buildServer.json`, it has no compile flags for Xcode targets and silently produces broken or hallucinated findings (e.g. "missing import" for a symbol that exists in another target).
- Even with the `xcode-build-server` bridge, `sourcekit-lsp`'s index is *build-pinned*: it refreshes only after an Xcode / `xcodebuild` build. Xcode's hosted SourceKit instance, by contrast, indexes live — same engine, same diagnostics that drive the Issue Navigator squiggles.
- Two diagnostic surfaces where one is wrong is worse than one surface that is right.

| Need | Use | Not |
|------|-----|-----|
| Live compiler diagnostics for a file | `mcp__xcode__XcodeRefreshCodeIssuesInFile` | `LSP` |
| Project-wide warnings/errors | `mcp__xcode__XcodeListNavigatorIssues` | `LSP` |
| Find symbol declarations or call sites | `mcp__xcode__XcodeGrep` / `mcp__xcode__XcodeGlob` | `LSP` (`goToDefinition` / `findReferences`) |
| Apple framework documentation | `mcp__xcode__DocumentationSearch` | guesswork |

Keep the `swift-lsp` Claude Code plugin disabled on these projects (`"swift-lsp@claude-plugins-official": false` in `~/.claude/settings.json`). Install `xcode-build-server` (Homebrew) only for a discrete session that needs heavy cross-file semantic refactoring; disable again afterwards — it is not a permanent contract.

## Gotchas

- **Tab identifier**: every Xcode MCP tool requires a `tabIdentifier`. Call `mcp__xcode__XcodeListWindows` at the start of a session to discover the correct value — do not hardcode it, as it depends on window open order.
- `mcp__xcode__XcodeMakeDir` requires `mcp__xcode__XcodeLS` to have been called first in the same session or it will fail with an error about unknown project structure.
- A project can mix synchronized folders and legacy groups. Do not assume everything is one or the other — check with `XcodeLS` or inspect `project.pbxproj` for `PBXFileSystemSynchronizedRootGroup` vs `PBXGroup`. For **legacy groups** (`PBXGroup`), use `XcodeWrite` — it adds a `PBXFileReference` and compile sources entry. For **synchronized folders** (`PBXFileSystemSynchronizedRootGroup`), use the filesystem `Write` tool directly into the synced directory instead — `XcodeWrite` places the file at the project root and omits it from the compile sources phase.
- **Git staging**: `XcodeUpdate` and `XcodeWrite` do NOT auto-stage their changes. Always `git add` the modified files explicitly before committing. (`XcodeRM` stages deletions automatically — the asymmetry is easy to miss.)
