---
description: Empty and error states are implemented before the happy path — a screen is not shippable without them
paths:
  - "**/*.swift"
  - "**/*.tsx"
  - "**/*.vue"
  - "**/*.kt"
  - "**/*.xml"
  - "**/*.html"
---

# UI State Coverage

Before writing any view that renders data from a `try` call or an optional, implement the empty state and error state views first — then the happy path. The happy path is not shippable without them.

This applies everywhere: lists that may be empty, async loads that may fail, optional environment values, optional model fields rendered in UI. If the data can be absent or the operation can fail, the UI must handle it explicitly before the success case is built.
