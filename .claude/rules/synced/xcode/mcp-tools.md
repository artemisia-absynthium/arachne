---
paths:
  - "**/*.swift"
  - "**/*.xcodeproj/**"
---

# Xcode MCP Tools

Plain filesystem tools are fine for reading and editing existing Swift files — the operations
below are where the MCP is required. Building and testing through the MCP, and opening the
workspace it needs, are `mcp-build-and-test.md`.

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

On Xcode projects, query diagnostics and symbols through the Xcode MCP's own tools; the
server's tool list is the authority on which exist.

## Gotchas

- `XcodeMakeDir` fails with an unknown-project-structure error unless `XcodeLS` has run
  earlier in the same session.
- **Git staging**: `XcodeUpdate` and `XcodeWrite` do NOT auto-stage their changes — `git add`
  the modified files explicitly before committing. `XcodeRM` stages deletions automatically;
  the asymmetry is easy to miss.
