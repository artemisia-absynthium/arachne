---
paths:
  - "**/*UITests*/**"
  - "**/*.swift"
---

# UI-Test Data Isolation — Redirect, Never Mutate In Place

## macOS UI tests run against the real app container

On iOS, XCUITest drives the app in a simulator; on macOS it launches the app **on the
host**, in its real sandbox container (`~/Library/Containers/<bundle-id>`). Any database,
file, or defaults store the app uses is the same one the locally installed build uses —
including a developer's dogfooding data. A test-configuration flag that mutates app state
in place ("wipe user tables and reseed", "clear caches on launch") destroys real data the
first time the Mac test plan runs. This has happened; nothing warns before it does.

## The rule

A launch flag that exists to give tests a known state must **redirect the app to
ephemeral storage**, never clean the real store:

```swift
// ✅ — the flag swaps the storage location; real data is untouchable by construction
static func openApplicationDatabase() async throws -> AppDatabase {
    #if DEBUG
    let arguments = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)
    if (arguments["uiTestEphemeralStore"] as? String) == "YES" {
        return try AppDatabase(path: NSTemporaryDirectory() + "\(UUID().uuidString).sqlite")
    }
    #endif
    // …open the real container store
}

// ❌ — the flag deletes rows in the live store; on macOS that is the developer's data
if launchFlagSet { try database.deleteAllUserData() }
```

Redirection is also the better test design: each launch gets a deterministic fresh state
(fixtures re-anchored at today), concurrent test processes cannot collide, and there is no
destructive code path left to guard.

## Read destructive-adjacent flags from the argument domain only

`UserDefaults.standard.bool(forKey:)` searches the argument domain *and then falls through
to the persisted domain* — a stray stored value (a `defaults write`, a debugging session,
a typo'd key) then satisfies the check on every subsequent launch with no launch argument
in sight. For any flag that changes where or how data is stored, read the volatile
argument domain explicitly, as above: it is rebuilt from `argv` each launch and can never
be persisted, so the flag is provable per-launch consent. (`-key YES` arrives in the
argument domain as the String `"YES"`, not a Bool.)

## Centralize the launch contract

Keep the UI-test launch arguments in one `XCUIApplication` factory extension in the test
target and route every suite through it. The app-side reader and test-side writer of a
flag cannot share a constant across targets, so a single writer is the only drift guard:

```swift
extension XCUIApplication {
    @MainActor
    static func launchedForUITests() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
            "-uiTestEphemeralStore", "YES"
        ]
        app.launch()
        return app
    }
}
```
