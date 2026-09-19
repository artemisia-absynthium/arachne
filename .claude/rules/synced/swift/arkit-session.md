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

## The host that keeps one session: `ARView` with manual configuration

`ARView(frame:cameraMode:automaticallyConfigureSession:)` with `automaticallyConfigureSession:
false` renders the passthrough from exactly the session you configure and run — `arView.session`
*is* the app's session, so there is nothing to bind and no second session can appear:

```swift
let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
let configuration = ARWorldTrackingConfiguration()
// … frame semantics, environment texturing …
arView.session.delegate = self
arView.session.run(configuration)
// RealityKit content goes under an anchor in arView.scene; SwiftUI hosts the view through
// UIViewRepresentable.
```

Own the `ARView` in the object that owns the session; every other surface reads
`arView.session`, none creates or runs one.

## `RealityView` + `SpatialTrackingSession.run(_:session:arConfiguration:)`: verify on a device first

Apple documents that a SwiftUI `RealityView` in AR mode (iOS 18+) can *bind* to an app-owned
session through `SpatialTrackingSession.run(_:session:arConfiguration:)` ("you manage and run the
ARKit session"), after which you call `arSession.run(_:)` yourself. On an iOS 26 device this path
**did not bind under any ordering** — view gated on a bind-completed flag, run then bind, bind
then run: the call returned `unavailableCapabilities` containing `.world` and `.camera`,
`RealityView` started RealityKit's own default tracking session alongside the app's, and the
two-session symptoms above followed (camera contention as a `FigCapture` capture error, a
permanent interruption over a working passthrough, frames piling up in the delegate, no raycast
hits). Treat the binding path as unverified on any OS you have not tried it on; when it fails, it
fails as two sessions, not as an error you can catch.

If you do try it: `run(_:session:arConfiguration:)` is declared only in the device SDK's
RealityKit interface, not the Simulator's, so wrap the call in `#if !targetEnvironment(simulator)`;
a `RealityView` whose content camera is `.spatialTracking` must not appear before the bind
completes, or it starts the default session first; and you must still call `arSession.run(_:)`
yourself — bound but not run means no delegate callbacks, tracking stuck in `initializing`, and
`currentFrame == nil`.

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
