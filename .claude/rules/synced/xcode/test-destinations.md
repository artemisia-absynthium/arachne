---
paths:
  - "**/*.xcodeproj/**"
  - "**/*.sh"
  - "**/*.yml"
  - "**/*.yaml"
---

# Test Destinations and Platform Coverage

## Run every platform the target supports

A green run on one platform is not evidence about any other. `SUPPORTED_PLATFORMS` on the app
target is the contract; the test matrix has to match it, or the untested platforms are shipping
on hope.

```bash
xcodebuild -showBuildSettings -scheme MyApp -json \
  | jq -r '.[0].buildSettings.SUPPORTED_PLATFORMS'   # e.g. "iphoneos iphonesimulator macosx"
```

This is not theoretical tidiness. Observed in a three-platform app: a single `import UIKit` in one
test file meant the **entire test target had never compiled for macOS** — for the life of the
project — while every run stayed green, because every run was an iPhone simulator. The Mac-only
code (menu commands, keyboard shortcuts) had never been executed by any test, and a bug that only
manifests when a sidebar and detail are visible together was found by code review rather than by
the suite.

Where a UI test asserts layout, remember that size class is part of the platform: a phone-width
and a regular-width run exercise different code paths through the same `NavigationSplitView`.

## Guard platform-specific imports in tests, or the matrix quietly shrinks

One platform-specific import in one test file removes a platform from the matrix, and nothing
reports it except a build failure nobody triggers. When a cross-platform API exists, prefer it
over `#if canImport(UIKit)` branches — one code path cannot drift per platform:

```swift
// ❌ drops macOS from the test matrix
import UIKit
let resolved = UIColor(resource: .brand).resolvedColor(with: .init(userInterfaceStyle: .dark))

// ✅ same values, every platform
import SwiftUI
var environment = EnvironmentValues()
environment.colorScheme = .dark
let resolved = Color(.brand).resolve(in: environment)
```

When porting a computation this way, anchor the port to values you already trust — assert the
*specific numbers* the old implementation produced, not merely that the result still passes a
threshold. A wrong color space, unit, or rounding can clear a threshold by luck.

## Resolve each destination; never hardcode a device or an OS

Both halves of `-destination 'platform=iOS Simulator,name=iPhone 17'` are stale constants waiting
to happen. The **name** ships with the toolchain — each Xcode major brings a new generation. The
name is also **ambiguous**: every device name exists once per installed runtime, so a bare `name=`
matches one device per runtime and xcodebuild resolves it silently, including onto a beta runtime.
Observed: the beta runtime refused to launch the UI test runner
(`FBSOpenApplicationServiceErrorDomain` … `RequestDenied`) while unit tests passed on both, so it
read as a broken UI test rather than a wrong destination.

Pinning `OS=` fixes the ambiguity and adds a second stale constant. Resolve both from the machine —
the SDK of the *selected* Xcode is the runtime the build is compiled against, and a UDID cannot be
ambiguous:

```bash
SDK=$(xcrun --sdk iphonesimulator --show-sdk-version)          # e.g. 26.5
RUNTIME="com.apple.CoreSimulator.SimRuntime.iOS-${SDK//./-}"   # …SimRuntime.iOS-26-5

# newest plain iPhone on that runtime; falls back to any iPhone if only Pro variants ship
device() { xcrun simctl list devices available -j | jq -r --arg r "$RUNTIME" --arg p "$1" '
  (.devices[$r] // []) as $all
  | (($all | map(select(.name | test("^" + $p + " [0-9]+$")))) as $plain
     | if ($plain | length) > 0 then $plain else ($all | map(select(.name | startswith($p)))) end)
  | sort_by(.name | capture("(?<n>[0-9]+)").n | tonumber) | last | .udid'; }

xcodebuild test -scheme MyApp -destination "id=$(device iPhone)"
xcodebuild test -scheme MyApp -destination "id=$(device iPad)"
xcodebuild test -scheme MyApp -destination 'platform=macOS,arch=arm64'
```

Use `--sdk watchsimulator` / `appletvsimulator` / `xrsimulator`, with the matching
`SimRuntime.watchOS-` / `tvOS-` / `xrOS-` prefix, for the other simulator platforms.

## Diagnose the destination before blaming the diff

When a target fails right after an unrelated change, hold the commit fixed and vary only the
destination: an explicit `id=<udid>` per candidate separates a runtime problem from a code problem
in two runs, without reading the diff at all.

`-showdestinations` prints the resolved set. Match the name exactly — a trailing-space pattern also
catches `iPhone 17 Pro` and `iPhone 17 Pro Max`, inflating the count and hiding the real duplication:

```bash
xcodebuild -showdestinations -scheme MyApp | grep -c "name:iPhone 17 }"   # exact device only
```

## Read the verdict, and never truncate the stream

Cold-boot launch denials are retried: a log can contain `RequestDenied` and still end in
`** TEST SUCCEEDED **`. Grep the terminal verdict, never error text.

Do not pipe a test run through `head`. When `head` exits it closes the pipe, `xcodebuild` takes
SIGPIPE mid-run, and the result is *neither* pass nor fail — an inconclusive run that reads like a
finished one. Redirect to a file, then query it:

```bash
xcodebuild test -scheme MyApp -destination "id=$UDID" > run.log 2>&1; echo "exit=$?"
grep -E "TEST SUCCEEDED|TEST FAILED" run.log
```

If a script waits for a build to finish, match the process name exactly — `pgrep -x xcodebuild`.
`pgrep -f "xcodebuild test …"` also matches the waiting shell's own command line, so the loop waits
for itself and never exits.
