# CLAUDE.md

## Build and test

CI runs the `xcodebuild` form below on every platform in `.github/workflows/swift.yml`.

```bash
swift build
swift test

# One test
swift test --filter "ArachneTests/<TestFunctionName>"

# Tests on a simulator platform — resolve the UDID as xcode/test-destinations.md prescribes.
# -skipPackagePluginValidation skips the trust prompt for the SwiftLint build tool plugin.
xcodebuild test -scheme Arachne -destination "id=<UDID>" -skipPackagePluginValidation
```

## Design constraints

Foundation only: no runtime dependencies, no Combine, no code generation, no platform-specific code in the library.

## Tests

Network calls are stubbed by `StubURLProtocol`, fed from each test service's `stubResponse` in `Tests/ArachneTests/Model/`: an endpoint under test is a case there.

## SwiftLint

It runs as `SwiftLintBuildToolPlugin` on both targets during every build; that build is the lint entry point. There is no `.swiftlint.yml`, so SwiftLint's default rules apply.

## Documentation

The DocC catalog `Sources/Arachne/Documentation.docc/` is published: a push to `main` rebuilds https://arachne.netlify.app (`.github/workflows/docc.yml`).
