---
description: Judge a test run by its executed-test count from the xcresult — exit codes lie in both directions and the parallel runner's stdout mangles result lines
---

# Test-Run Verification

A test run is judged by its **executed-test count**, never by exit status: a run that
builds and exits 0 can have executed nothing (stale scheme, wrong destination, stuck
simulator), and a failing exit can be one documented fixture failure away from green.

Count from the **xcresult**, not the log. The parallel test runner interleaves output
from its clone workers, and interleaving can mangle result lines mid-name — a passing
test then looks missing from the log while the run was fine. The xcresult bundle is
authoritative:

```sh
xcrun xcresulttool get test-results summary --path <run>.xcresult \
  | jq '{totalTestCount, passedTests, failedTests, skippedTests}'
```

(The `.xcresult` path is printed near the end of every `xcodebuild test` log.)

Compare `totalTestCount` against the suite's known baseline: a shrunken count is a
silent non-execution, which no exit code reports.

## Two tools, two counts — a baseline names its source

The Xcode MCP's `RunAllTests` / `RunSomeTests` report one result **per parameterized case**
(a Swift Testing `@Test(arguments:)` with eight rows counts eight), while
`xcresulttool get test-results summary` on the same `.xcresult` reports `totalTestCount` **per
test function** (that test counts once). Observed with Xcode 27.0 on an iOS 27.0 device: the
MCP said 195 tests, the bundle said 152, for one run with nothing skipped or failed.

Both are correct; they measure different things. A baseline written down without saying which
tool produced it is a false alarm waiting to happen — a "shrunken count" that is only the other
tool's count. When you record a baseline, or compare a run to one, name the tool
(`xcresult functions` vs `MCP cases`), and keep the baseline where the check reads it, not in
prose (`workflow/docs-record-decisions.md`).
