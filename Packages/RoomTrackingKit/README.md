# RoomTrackingKit

RoomTrackingKit wraps ARKit's `RoomTrackingProvider` so you can capture the layout of the current room and share it with other devices.

## Adding the Package
1. In Xcode choose **File > Add Packages…**.
2. Enter the path to this repository and select **RoomTrackingKit**.
3. Add the `RoomTrackingKit` product to your app target.

## Start Room Tracking
Create a tracking manager and start it from a task, similar to how `IntroView` starts world and hand tracking tasks.

```swift
import RoomTrackingKit

@StateObject private var roomTracker = RoomTrackingManager()

var body: some View {
    RealityView { content in
        // add content when a room anchor is available
        if let room = roomTracker.currentRoomAnchor {
            content.add(ModelEntity(), anchor: room)
        }
    }
    // Start tracking when the view appears
    .task { await roomTracker.startTracking() }
}
```

## Place a Model
Once tracking begins and a `RoomAnchor` is provided, attach your model entity to that anchor:

```swift
if let room = roomTracker.currentRoomAnchor {
    content.add(modelEntity, anchor: room)
}
```

## Lock the Position
After confirming the placement you can stop updates to the anchor so it remains fixed:

```swift
roomTracker.lockCurrentRoom()
```

## Share with Peers
`RoomTrackingManager` can package the current room information and send it through MultipeerConnectivity:

```swift
.task {
    try await roomTracker.share()
}
```

## Example Usage
Below is a minimal SwiftUI view, modeled after `IntroView`, that starts room tracking, places a model, locks its position, and shares the room data:

```swift
struct RoomDemoView: View {
    @StateObject private var roomTracker = RoomTrackingManager()

    var body: some View {
        RealityView { content in
            if let room = roomTracker.currentRoomAnchor {
                content.add(ModelEntity(), anchor: room)
            }
        }
        .task { await roomTracker.startTracking() }
        .task { try? await roomTracker.share() }
    }
}
```
