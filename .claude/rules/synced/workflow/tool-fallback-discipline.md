---
paths:
  - "**/*"   # tooling discipline applies to every session, whatever files it touches
---

# Tool Fallback Discipline — Unavailable ≠ Broken

When a preferred tool (an MCP tool, a project-mandated wrapper) errors while its
backend is actually available, that failure is a **bug to diagnose** — never a
silent trigger to fall back to a CLI or lower-level equivalent.

The distinction that governs:

- **Unavailable** — the MCP server is not running, the host app is closed, the
  tool is not installed. Falling back to the documented CLI equivalent is
  legitimate and expected. Note the fallback in the session output.
- **Available but erroring** — the tool responds with an error, however opaque.
  This is a defect in the tool, its configuration, or its invocation. Diagnose
  it in-session; if the diagnosis must be deferred, document the exact failure
  (tool, input, verbatim error) in the project's CLAUDE.md or an issue before
  proceeding via fallback.

Rationale: a silent fallback hides the tool defect indefinitely — every future
session pays the fallback cost and re-discovers the same failure, and the
preferred tool's advantages (host-app integration, correct project state,
richer diagnostics) are quietly lost. One session's diagnosis is cheaper than
every session's workaround.

Example: a project's test-runner MCP tool returns an opaque "data missing"
error while the host IDE is open and its other tools work. Wrong: switch to the
CLI test runner for the rest of the session and move on. Right: probe the
failing tool with a minimal invocation, fix or characterize the failure, and
record it if unresolved — then use the fallback with the defect on the record.
