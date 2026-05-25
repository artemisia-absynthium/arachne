---
paths:
  - "**/*.swift"
  - "**/*.xcodeproj/**"
---

# Warning Discipline

## Zero-warnings policy

The project must compile with **zero warnings** at all times — no exceptions.

- **Before starting any task**: check for existing warnings. If any are present, fix them first in a separate, independent commit before touching the requested work — even if the user did not ask.
- **Never commit code that introduces new warnings.** A warning-free build is a pre-condition for every commit, not a post-task cleanup step.
- **After Xcode upgrades**: new toolchain warnings are treated as bugs. Fix them before any other work and land them in their own commit so the cleanup is isolated from feature changes.

## SwiftLint suppression policy

Fix SwiftLint violations. Suppress only when the violation is a false positive or the correct fix would produce materially worse code.

**Never modify `.swiftlint.yml`** to silence a rule project-wide. A global disable hides real issues across the entire codebase and cannot be safely undone without auditing every affected file.

When suppression is genuinely warranted, use the narrowest scope possible and justify it immediately above:

```swift
// Bundle lookup returns non-nil by construction — resource is bundled at build time.
// swiftlint:disable:next force_unwrapping
let configURL = bundle.url(forResource: "Config", withExtension: "plist")!
```

For multi-line suppression, re-enable immediately after the offending lines:

```swift
// Dequeue is guaranteed by storyboard registration in viewDidLoad.
// swiftlint:disable force_cast
let cell = tableView.dequeueReusableCell(withIdentifier: id) as! MyCell
// swiftlint:enable force_cast
```

Rules:
- Every suppression **must** have a comment explaining *why* the fix would be worse than the suppression — not just *what* is being suppressed. A bare `// swiftlint:disable` with no rationale is rejected in code review.
- Before suppressing, ask: can the code be restructured so the violation disappears entirely?