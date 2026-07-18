---
paths:
  - "**/*.xcscheme"
  - "**/*.xcodeproj/**"
---

# Scheme File Discipline

## GUI edits clobber hand-made scheme edits

Xcode rewrites the **entire** `.xcscheme` file whenever a scheme is touched in
the GUI (Edit Scheme, changing any option, sometimes just opening the editor).
Hand-made XML edits are silently discarded in the rewrite: skipped testables
flip back, `shouldUseLaunchSchemeArgsEnv` reverts, `StoreKitConfigurationFileReference`
entries move or vanish, and XML comments are stripped.

Consequences observed in practice: a UI test target deliberately marked
`skipped = "YES"` was silently re-enabled in the unit-test gate, and restored
launch-argument inheritance leaked a debug launch argument into the unit-test
host, breaking tests that assert the un-bypassed behavior.

Rules:

- **After any GUI scheme edit — yours or the user's — re-read the scheme file
  and re-verify its hand-maintained invariants** before running tests or
  committing. Treat an unexpected `.xcscheme` diff as a red flag, not noise.
- **Document scheme invariants in the project's CLAUDE.md** (which testables
  must stay skipped, whether the Test action may inherit Run arguments, which
  StoreKit configuration each action uses) so they can be re-applied after a
  rewrite instead of being rediscovered through test failures.
- When a hand edit must survive, prefer expressing the intent through means
  Xcode preserves (e.g. a separate scheme for the special workflow) over
  fighting the rewrite inside a GUI-managed scheme.

## Launch arguments leak into the unit-test host

With `shouldUseLaunchSchemeArgsEnv = "YES"` (the default) on the Test action,
the Run action's launch arguments and environment are applied to the unit-test
host app. A debug convenience argument enabled for Run sessions (e.g. a
quota/paywall bypass flag) then silently alters production code paths
under test:

```swift
// Production code gated on a debug launch argument…
static var quotaDisabled: Bool {
    CommandLine.arguments.contains("-quotaDisabled")
}

// …reads the TEST HOST's arguments during unit tests, which include the
// Run action's arguments when shouldUseLaunchSchemeArgsEnv = "YES".
```

Rule: schemes whose Run action carries behavior-altering debug arguments must
set `shouldUseLaunchSchemeArgsEnv = "NO"` on the Test action (untick "Use the
Run action's arguments and environment variables" in the scheme editor), so
tests always exercise the un-bypassed code paths.
