---
description: Xcode MCP tool usage — file operations, directory listing, project structure
globs:
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

## Diagnostics

| Task | Use |
|------|-----|
| Refresh code issues in a file | `mcp__xcode__XcodeRefreshCodeIssuesInFile` |
| List navigator issues | `mcp__xcode__XcodeListNavigatorIssues` |

## Gotchas

- **Tab identifier**: every Xcode MCP tool requires a `tabIdentifier`. Call `mcp__xcode__XcodeListWindows` at the start of a session to discover the correct value — do not hardcode it, as it depends on window open order.
- `mcp__xcode__XcodeMakeDir` requires `mcp__xcode__XcodeLS` to have been called first in the same session or it will fail with an error about unknown project structure.
- A project can mix synchronized folders and legacy groups. Do not assume everything is one or the other — check with `XcodeLS` or inspect `project.pbxproj` for `PBXFileSystemSynchronizedRootGroup` vs `PBXGroup`. `XcodeWrite` is safe for both; it adds to `project.pbxproj` only when the parent is a legacy group.
