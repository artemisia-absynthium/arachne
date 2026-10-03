---
description: Deployment environments (dev/staging/prod) are build configurations reading one xcconfig each — never one target per environment, not even as an alternative to list and reject.
---

# Environments Are Build Configurations, Never Targets

A target is a *product*: one binary, one set of sources and resources, one bundle. A deployment
environment is a *setting*: which backend an install reaches, which identity it signs with, which
container it owns. Xcode has exactly one axis along which settings vary for the same product — the
build configuration — and that is where environments live.

**Never propose one target per environment.** Not as the recommendation, not as a fallback, not as
an alternative to name and dismiss. The option does not go on the table:

- Every source file and resource has to join every target. Membership drifts silently, and the
  production target ships code the development target never compiled, or the reverse.
- Build phases, dependencies, package links, test targets, Info.plists and entitlements all
  duplicate, and every later change has to be made N times.
- Each target needs its own signing identity and App Store Connect record, so an environment
  costs provisioning work instead of a file.
- It couples compilation options to deployment, two orthogonal concerns: a "staging" target
  cannot be built in both debug and release without doubling the targets again.

## The shape that works

One xcconfig per environment, attached at the **project** level to the configurations that belong
to it, declaring every value the environment owns; the project file expands them and holds no
literal:

```
// Config/Dev.xcconfig
#include "Shared.xcconfig"

APP_BUNDLE_ID    = com.example.myapp.dev
APP_DISPLAY_NAME = MyApp Dev
API_BASE_URL     = https:/$()/api-dev.example.com   // `/$()/` keeps the `//` out of the comment parser
```

```
// in every target: expansions, never values
PRODUCT_BUNDLE_IDENTIFIER = $(APP_BUNDLE_ID)
INFOPLIST_KEY_CFBundleDisplayName = $(APP_DISPLAY_NAME)
```

Code reads the values through `Info.plist`, never from a Swift literal, so the same source compiles
for every environment.

**Count configurations before inventing a mechanism.** Settings vary only by configuration: a scheme
*selects* one per action, a destination selects an SDK, a run carries arguments and environment
variables, and none of them can set a build setting. Two independent axes therefore multiply —
three environments that each need a debug and a release flavour are six configurations, by
arithmetic, not by accident. Duplicated settings dictionaries are the price; pay it with one
target-level xcconfig per target holding the target's invariant settings (the per-configuration
dictionaries then stay empty), or with a guard that compares the dictionaries as data.

The one legitimate overlay that adds no configuration is `xcodebuild -xcconfig <file>`, for
CI-only variation. Scheme pre-action scripts that write an xcconfig on the fly are not: the build
then depends on which scheme ran last, and `xcodebuild` from CI never runs them.

## Custom configuration names are safe for packages

Measured (Xcode 27, 2026-10): what reaches a Swift package dependency — optimisation level, the
`DEBUG` condition, testability — is derived from the resolved settings of the configuration being
built, not from its name. A configuration named `DevDebug`, or a plain `Debug` renamed to
`Development` with its settings untouched, compiles packages with `-Onone -DDEBUG -enable-testing`;
a configuration carrying release settings compiles them optimised whatever it is called. Do not
avoid descriptive configuration names on the belief that packages key on the literal `Debug`.
