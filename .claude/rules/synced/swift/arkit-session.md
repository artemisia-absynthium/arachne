---
paths:
  - "**/*.swift"
---

# ARKit Sessions (iOS, iPadOS)

## Exactly one `ARSession` runs at a time

Two running `ARSession`s fight for the camera. The symptoms are misleading: the passthrough
keeps rendering (from one session) while the other reports a permanent interruption
(`sessionWasInterrupted` with capture errors), frame rate collapses, and raycasts return
nothing because the starved session never accumulates features.

Own the session in one place — one object creates it, runs it, pauses it — and make every
AR surface depend on that object. Nothing else creates an `ARSession`.

## RealityKit binds to your session; it does not run it

With a SwiftUI `RealityView` in AR mode (iOS 18+ / iPadOS 18+), the app can keep ownership of the ARKit session:

```swift
let spatial = SpatialTrackingSession()
let configuration = ARWorldTrackingConfiguration()
// … frame semantics, environment texturing …
await spatial.run(
    SpatialTrackingSession.Configuration(tracking: [.camera, .world], camera: .back),
    session: arSession,
    arConfiguration: configuration
)
arSession.run(configuration)   // RealityKit only bound to it — you run it ("you manage and run the ARKit session")
```

Two ordering rules follow, and both were learned from a device, not a build:

- **Call `arSession.run(_:)` yourself.** After `run(_:session:arConfiguration:)` alone the session
  is bound but idle: no delegate callbacks, tracking never leaves `initializing`, and
  `currentFrame` is `nil` — every raycast fails.
- **Bind before the view appears.** A `RealityView` whose content camera is `.spatialTracking`
  starts RealityKit's *default* tracking session the moment it appears if no
  `SpatialTrackingSession` is running yet. Calling `run(_:session:arConfiguration:)` afterwards
  returns `unavailableCapabilities` containing `.world` and `.camera`, RealityKit stays on its own
  session, and you are back to two sessions. Gate the view on a flag that flips only after the
  bind-and-run completes:

```swift
@Observable @MainActor final class ARScreenModel {
    private(set) var isSessionBound = false
    func start() async {
        await tracking.start()        // spatial.run(…, session:, arConfiguration:) + arSession.run
        isSessionBound = true         // only now may a RealityView with .spatialTracking appear
    }
}
```

`run(_:session:arConfiguration:)` is declared only in the device SDK's RealityKit interface,
not the Simulator's; wrap the call in `#if !targetEnvironment(simulator)` (the Simulator cannot
run ARKit anyway).

## Keep the `ARSession` delegate off the main queue

`delegateQueue` defaults to the main queue. Frames are retained until the delegate returns, so
behind a busy renderer they pile up and ARKit warns *"The delegate of ARSession is retaining N
ARFrames. The camera will stop delivering camera images…"*. Give the session a private serial
queue and keep the delegate methods `nonisolated`, forwarding only `Sendable` values (an
`AsyncStream` continuation, a logger) to whatever is actor-isolated:

```swift
arSession.delegate = self
arSession.delegateQueue = DispatchQueue(label: "com.example.myapp.arsession", qos: .userInteractive)

nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
    continuation.yield(.frame(timestamp: frame.timestamp, hasDepth: frame.sceneDepth != nil))
}
```

Never store an `ARFrame` beyond the callback; extract what you need and let it go.
