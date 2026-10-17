---
paths:
  - "**/*.xcodeproj/**"
  - "**/Info.plist"
  - "**/*.xcconfig"
---

# Info.plist Values Come From Build Settings First

A generated Info.plist (`GENERATE_INFOPLIST_FILE = YES`) takes its keys from `INFOPLIST_KEY_*`
build settings, and that is where every key goes first: a setting is one line per configuration,
diffs like any other setting, and stays with the environment mechanism in `environments.md`. An
`Info.plist` file (`INFOPLIST_FILE`, merged with the generated keys) is the fallback for a key
Xcode does not emit from a setting — never the default, and never for a key that has a setting form.

**Decide from the artifact, not from the setting.** A setting that resolves in
`xcodebuild -showBuildSettings` can still be absent from the built app's plist; the check is the
bundle:

```sh
/usr/libexec/PlistBuddy -c 'Print :UIApplicationSceneManifest' "<built>.app/Info.plist"
```

Known case: `UIApplicationPreferredDefaultSceneSessionRole` — the key that makes an immersive
space a visionOS app's default scene — resolves as `INFOPLIST_KEY_…` but never lands in the plist,
even with `INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES`. Xcode's own visionOS app
template writes that manifest in a file, which is the signal that no setting form exists:

```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <true/>
    <key>UIApplicationPreferredDefaultSceneSessionRole</key>
    <string>UISceneSessionRoleImmersiveSpaceApplication</string>
</dict>
```

Two gotchas on the fallback:

- An `Info.plist` inside a synchronized root group is also copied as a resource, and the build
  fails with "Multiple commands produce … Info.plist". The group needs a
  `PBXFileSystemSynchronizedBuildFileExceptionSet` with `membershipExceptions = (Info.plist)`,
  which is what Xcode itself generates for a template project.
- The Xcode MCP's build-setting tool rejects `INFOPLIST_KEY_*` names outside its known list, so
  such a setting goes into the project file directly; the generated-plist check above then proves
  whether it took effect.

Rationale: the file is a second place where the same value can live, and a value that lives in
two places drifts. Keeping the file for keys that have no other home keeps every other key where
the environment and configuration machinery already reads it.
