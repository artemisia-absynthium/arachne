---
paths:
  - "**/*.swift"
---

# Date Formatting

## Use typed FormatStyle APIs for all date formatting

`DateFormatter` is superseded by the `FormatStyle` family. Never use `DateFormatter` in new code. Use the appropriate typed API for each use case:

| Use case | API |
|---|---|
| Machine-readable ISO 8601 | `Date.ISO8601FormatStyle` |
| User-facing display | `Date.FormatStyle` (`.formatted(date:time:)`) |
| Fixed custom non-ISO format | `Date.VerbatimFormatStyle` |

`DateFormatter` is stringly-typed, invisible to the compiler, and silently wrong under locale or calendar variations. The `FormatStyle` family is type-safe, composable, and the current Apple-recommended replacement.

```swift
// ✅ — machine-readable ISO 8601
private static var datetimeStyle: Date.ISO8601FormatStyle {
    Date.ISO8601FormatStyle()
        .locale(Locale(identifier: "en_US_POSIX"))
        .year().month().day()
        .dateSeparator(.dash)
        .dateTimeSeparator(.space)
        .time(includingFractionalSeconds: false)
        .timeSeparator(.colon)
}

// ✅ — user-facing display
date.formatted(date: .long, time: .shortened)
date.formatted(.dateTime.year().month().day())

// ❌ — DateFormatter is superseded; do not use in new code
let formatter = DateFormatter()
formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
```

## Always set locale to en_US_POSIX for machine-readable date formatting

When using any `FormatStyle` for fixed-format machine-readable dates (server responses, persistence), always set `.locale(Locale(identifier: "en_US_POSIX"))`.

Apple Technical Q&A QA1480 documents why: on devices with non-Gregorian calendars or certain regional settings, the default locale causes format styles to interpret or produce values differently, silently producing wrong results. `en_US_POSIX` guarantees the Gregorian calendar and ASCII digit interpretation regardless of the user's device locale.

**Exception:** do not set `en_US_POSIX` on `Date.FormatStyle` used for user-facing display — the device locale is the intended behavior there.

```swift
// ✅ — explicit locale, safe on all devices
Date.ISO8601FormatStyle()
    .locale(Locale(identifier: "en_US_POSIX"))
    .year().month().day()
    .dateSeparator(.dash)

// ❌ — relies on device locale; silently wrong on Arabic, Hebrew, or Persian calendar devices
Date.ISO8601FormatStyle()
    .year().month().day()
    .dateSeparator(.dash)
```
