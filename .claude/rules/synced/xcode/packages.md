---
paths:
  - "**/*.swift"
  - "**/Package.swift"
  - "**/*.xcodeproj/**"
---

# Package Management

Use Swift Package Manager exclusively. Do not introduce CocoaPods or Carthage.

- Add dependencies via SPM in Xcode or `Package.swift`.
- Pin dependencies to specific versions or commits — do not track `main` or `master` directly.
- A dependency bump is an explicit choice; it should appear as a deliberate diff in `Package.resolved`.

## Workspace Package.resolved churn

Xcode auto-resolves packages on branch switches and dirties the workspace
`Package.resolved` (`originHash` flips) — which then blocks `git switch`/`git rebase`
with "unstaged changes". The committed version is the truth: `git checkout --` the
churn before switching or rebasing. Never commit it unless a dependency bump is the
intent (see above — a bump is a deliberate diff).
