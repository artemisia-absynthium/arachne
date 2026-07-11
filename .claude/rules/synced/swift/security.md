---
paths:
  - "**/*.swift"
---

# Security

## Archive extraction — use the containment-guarded API

When extracting archives (zip, tar), always use the high-level API that enforces
destination containment. Never extract entries one-by-one with a low-level API unless
you add an explicit path-containment check yourself.

Low-level per-entry APIs typically carry **no zip-slip protection**: an archive entry
named `../escaped.txt` resolves outside the extraction directory and writes wherever
the traversal lands. In ZIPFoundation specifically, the traversal guard lives only in
`FileManager.unzipItem(at:to:)` — `Archive.extract(_:to:)` trusts the destination URL
it is given.

```swift
// ✅ — containment check per entry (plus CRC32 verification) built in
try FileManager.default.unzipItem(at: archiveURL, to: destinationDirectory)

// ❌ — no traversal guard; "../"-prefixed entry paths escape destinationDirectory
for entry in archive {
    try archive.extract(entry, to: destinationDirectory.appending(path: entry.path))
}
```

If per-entry extraction is genuinely required (selective extraction, custom progress),
guard each destination before extracting. A naive `standardized`-prefix comparison is
not enough — a crafted `/../` entry combined with a doubled path separator expands
differently in `URL.standardized` than in POSIX `fopen`, bypassing the check
(ZIPFoundation issue #281). Reuse the library's hardened helper instead:

```swift
let destination = destinationDirectory.appending(path: entry.path)
guard destination.isContained(in: destinationDirectory) else {   // ZIPFoundation public API
    throw CocoaError(.fileReadInvalidFileName)
}
try archive.extract(entry, to: destination)
```

A SHA/signature check on the whole archive mitigates the risk only when it is
mandatory and the source is trusted; treat it as defense in depth, not a substitute
for containment.
