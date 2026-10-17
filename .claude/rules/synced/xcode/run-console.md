---
description: A run started from the Xcode GUI is not an MCP launch session and the xcresult console exporter returns an empty list for it — read the run's console from the Zstandard blobs inside its Logs/Launch xcresult and triage by sender image, never by message text
---

# Run Console — Read It From the Run's xcresult, Triage by Sender

A "check the console for developer errors" request after a manual run on a device has no
text log to open. Two tools that look like they answer it do not:

- The Xcode MCP's `GetConsoleOutput` knows only launch sessions the MCP itself started. A run
  launched from Xcode's Run button is not one of them: the default session resolves to the
  MCP's last test or run, and any other reference fails with `Could not find launch session`.
  That is a capability gap, not an erroring tool, so reading the bundle directly is not a
  fallback in the sense of the tool-fallback rule — there is no MCP defect to diagnose first.
- `xcrun xcresulttool get log --type console` on the run's bundle returns `"items": []`,
  while `--type action` and `--type build` in the same bundle are populated. Observed with
  Xcode 27.0 on a run installed over the network on an iOS 27.0.1 device.

The console is nevertheless in that bundle. Xcode records every Run action as

```
~/Library/Developer/Xcode/DerivedData/<Project>-<hash>/Logs/Launch/Run-<Scheme>-<date>.xcresult
```

with `LogStoreManifest.plist` beside it as the index. `--type action` is the place to confirm
which run it was — platform, OS version, model, the install steps — before reading anything.
The console entries live in the bundle's `Data/data.0~*` blobs: Zstandard streams of Xcode's
own key-length serialization, where each `OSLogEntry` carries `category`, `message`,
`messageType` (16 is error, 17 is fault), `subsystem`, `senderImageName` and `senderWallTime`.

A tally by sender and severity needs no parser; `zstd` is the only dependency. The record
layout the patterns match is Xcode's private format, verified on Xcode 27.0 and nowhere
documented: on a new Xcode major, confirm the pipeline still prints rows before trusting an
empty result as a clean console — an empty tally is the same answer the console exporter gave.

```sh
X=~/Library/Developer/Xcode/DerivedData/<Project>-<hash>/Logs/Launch/Run-<Scheme>-<date>.xcresult
zstd -dc "$X"/Data/data.0~* \
  | LC_ALL=C grep -aoE 'messageType\[(S9:OSLogType|T\[K2:_nV9:OSLogType\])K2:_vV[0-9]+:[0-9]+|senderImageName\[S6:StringK2:_vV[0-9]+:[A-Za-z0-9_.-]+' \
  | sed -E 's/.*_vV[0-9]+://' | paste - - | sort | uniq -c | sort -rn
```

The message texts, for the senders the tally singles out:

```sh
zstd -dc "$X"/Data/data.0~* \
  | LC_ALL=C grep -aoE 'K7:message\[S6:StringK2:_vV[0-9]+:[^]]{0,160}' \
  | sed -E 's/.*_vV[0-9]+://' | sort | uniq -c | sort -rn
```

## Triage by sender image, not by message text

The sender image is the binary that emitted the line, and it decides the verdict. A message
that names the app's bundle path, its process, or "your" view controller but is sent by
`WebKit`, `UIKitCore`, `CameraUI`, `CoreServices` or `QuartzCore` is the OS talking to itself
inside the app's process: WebContent sandbox extensions, RunningBoard assertions refused for
browser-engine entitlements an app does not hold, the system camera's mode negotiation,
deprecated status-bar calls made by the camera UI, a Photos picker loading as an extension.
None of those is a defect in the app, and none can be fixed from the app. A line sent by the
app's own image, or logged under the app's own subsystem, is the only kind that is.

Rationale: message text is written to describe the OS's problem, so it reads as an error
whoever caused it, and a triage by text either flags everything or reads every line twice. The
sender field makes the split mechanical and lets the app's own lines be listed in one grep.

What is not a shortcut: `log collect --device-udid` needs root, and `devicectl` has no log
subcommand. The run bundle is the one place the console already is.

The executed-test count of a *test* run is a different question with its own bundle and its
own tool — `test-verification.md`.
