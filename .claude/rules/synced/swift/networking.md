---
paths:
  - "**/*.swift"
---

# Networking

## Reachability is never a preflight

Never gate, skip or refuse a network operation on a reachability answer — `NWPathMonitor`'s
path status, `SCNetworkReachability` flags, or an `isConnected` flag cached from either.
Attempt the operation; connectivity is whatever the attempt's outcome says. Apple's networking
guide: "Always attempt to make a connection. Do not attempt to guess whether network service is
available, and do not cache that determination."

Rationale: the path can change between the check and the request, so the error path has to
exist anyway; all a preflight adds is false negatives — a request that would have worked (an
on-demand VPN, an interface coming up) never runs, and the user is told to retry something the
app will refuse again. Apple DTS: "it's critical that you not prevent the user from issuing a
network request just because `NWPathMonitor` says it's not going to work. Don't disable your
Retry button based on the state returned by `NWPathMonitor`."

`NWPathMonitor` is not the preflight's modern replacement. The SDK's deprecation of
`SCNetworkReachability` (iOS 17.4, macOS 14.4) splits the job: "Use URLSession or NWConnection
to create connections that dynamically handle changing networks. Use NWPathMonitor to enumerate
available network interfaces."

```swift
// ❌ refuses a request that might have worked; the flag is a guess until the first update
func download() {
    guard reachability.isConnected else { showOfflineAlert(); return }
    startDownload()
}

// ✅ attempt; the error decides, the path only triggers the retry
func download() async {
    do {
        try await startDownload()
    } catch let error as URLError where error.isTransientConnectivity {  // app-defined set of codes
        showConnectionAlert()
        retryWhenPathIsSatisfied()
    } catch {
        showDownloadFailed(error)
    }
}
```

## What path monitoring is for

- **Diagnosing a failure** after it happened, and **triggering a retry** when the path becomes
  satisfied — the request's own error, not the path, classifies the failure.
- **Retrying a transient failure on its own schedule too**, with increasing backoff: a request
  can fail on a network the path still reports satisfied (upstream down behind working Wi-Fi), and
  no path change will ever come to retry it.
- **Status where no operation can report waiting.** Background `URLSession` tasks always wait for
  connectivity and never call `urlSession(_:taskIsWaitingForConnectivity:)`; a non-modal "waiting
  for network" note may come from the path. A foreground request reports waiting itself when the
  session sets `waitsForConnectivity`.
- **Interface preferences are request constraints** (`allowsExpensiveNetworkAccess`,
  `allowsConstrainedNetworkAccess`), never a check of the current interface before the request.

Speed follows the same rule. Apple: "There is only one way to determine the network's speed: use
it." A quality or bitrate decision measures the real transfer, never the interface type.

Sources: Apple, *Networking Overview — Designing for Real-World Networks* (archived guide);
`SCNetworkReachability.h` and `NSURLSession.h` in the SDK; Apple DTS on the Developer Forums,
thread 808401 (2025).
