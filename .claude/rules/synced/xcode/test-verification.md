---
description: Judge a test run by its executed-test count from the xcresult — exit codes lie in both directions and the parallel runner's stdout mangles result lines
paths:
  - "**/*"
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
