---
paths:
  - "**/*.swift"
  - "**/Package.swift"
  - "**/*.xcodeproj/**"
---

# Package Management

Use Swift Package Manager exclusively. Do not introduce CocoaPods or Carthage.

- Add dependencies via SPM in Xcode or `Package.swift`.
- Use `upToNextMajorVersion` ("Up to Next Major Version") requirements — never track
  `main`/`master`, and do not use `exactVersion`: the version lock already lives in
  `Package.resolved`, so an exact requirement duplicates it and forces a project-file
  edit for every patch release, while the major boundary still fences off breaking
  changes.
- `Package.resolved` is the lock file and must be committed — never gitignored.
- A dependency bump is an explicit choice; it should appear as a deliberate diff in `Package.resolved`.

## Workspace Package.resolved churn

Xcode auto-resolves packages on branch switches and dirties the workspace
`Package.resolved` (`originHash` flips) — which then blocks `git switch`/`git rebase`
with "unstaged changes". The committed version is the truth: `git checkout --` the
churn before switching or rebasing. Never commit it unless a dependency bump is the
intent (see above — a bump is a deliberate diff).
