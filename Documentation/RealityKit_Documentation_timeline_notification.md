# RealityKit Timeline Notifications Guide

This guide explains how to use RealityKit's timeline notifications to trigger custom behaviors from Reality Composer Pro animations.

## Overview

Reality Composer Pro timelines can send notifications at specific points during an animation. These notifications can be received in your Swift code to trigger additional behaviors, making it easy to coordinate animations with game logic.

## Implementation Steps

### 1. Define Custom Notification Names

Create an extension to `Notification.Name` to define your custom notification names:

```swift
extension Notification.Name {
    // Define notification names that match what you'll use in Reality Composer Pro
    static let antigenAttachedNotification = Notification.Name("AntigenAttached")
    static let adcDestroyedNotification = Notification.Name("ADCDestroyed")
    static let cancerCellDestroyedNotification = Notification.Name("CancerCellDestroyed")
}
```

### 2. Set Up Notification Listeners

In your SwiftUI view or custom class, create publishers for your notifications:

```swift
struct GameView: View {
    // Create publishers for each notification
    private let antigenAttachedReceived = NotificationCenter.default.publisher(
        for: .antigenAttachedNotification
    )
    private let adcDestroyedReceived = NotificationCenter.default.publisher(
        for: .adcDestroyedNotification
    )
    
    var body: some View {
        RealityView { content in
            // Your RealityView setup...
        }
        .onReceive(antigenAttachedReceived) { (output) in
            guard let entity = output.userInfo?["RealityKit.NotifyAction.SourceEntity"] as? Entity else { return }
            // Handle antigen attached notification
        }
        .onReceive(adcDestroyedReceived) { (output) in
            guard let entity = output.userInfo?["RealityKit.NotifyAction.SourceEntity"] as? Entity else { return }
            // Handle ADC destroyed notification
        }
    }
}
```

### 3. Reality Composer Pro Setup

1. Open your USDZ file in Reality Composer Pro
2. Select the entity you want to animate
3. Open the Timeline Editor
4. Add a new timeline animation
5. Add a "Notify" action at the desired point in the timeline
6. In the Notify action's properties:
   - Set the "Name" field to match your notification name (e.g., "AntigenAttached")
   - The entity with the timeline will be automatically sent as the source entity

### 4. Handling Notifications

When handling notifications, you can:
- Access the source entity that triggered the notification
- Get the scene and find related entities
- Trigger additional animations or state changes
- Update game logic or UI

Example handler:
```swift
.onReceive(antigenAttachedReceived) { (output) in
    guard let entity = output.userInfo?["RealityKit.NotifyAction.SourceEntity"] as? Entity else { return }
    
    // Example: Find and update related entities
    if let parentEntity = entity.parent {
        // Update parent entity
    }
    
    // Example: Trigger game logic
    updateScore()
    checkGameState()
    
    // Example: Start a new animation sequence
    startNextAnimation(for: entity)
}
```

## Best Practices

1. **Naming Conventions**:
   - Use clear, descriptive names for your notifications
   - Keep a consistent naming pattern
   - Document all notification names in one place

2. **Error Handling**:
   - Always use guard statements to safely unwrap notification data
   - Handle cases where entities might not exist
   - Add debug logging for notification events

3. **Timeline Organization**:
   - Keep animations modular and reusable
   - Use meaningful names for timelines
   - Document the purpose of each notification in the timeline

4. **Performance**:
   - Only create listeners for notifications you need
   - Clean up listeners when views are destroyed
   - Avoid heavy processing in notification handlers

## Example Use Cases

1. **Animation Chaining**:
   - Trigger follow-up animations after a main animation completes
   - Coordinate animations between multiple entities

2. **Game Logic**:
   - Update game state based on animation progress
   - Trigger particle effects or sound effects
   - Update UI elements or scores

3. **Entity Management**:
   - Clean up or spawn entities at specific animation points
   - Update entity properties or components
   - Trigger physics interactions

## Debugging Tips

1. Add print statements in notification handlers:
```swift
.onReceive(antigenAttachedReceived) { (output) in
    print("🎯 Received antigenAttached notification")
    guard let entity = output.userInfo?["RealityKit.NotifyAction.SourceEntity"] as? Entity else {
        print("⚠️ No source entity found in notification")
        return
    }
    print("✅ Found source entity: \(entity.name)")
}
```

2. Use Reality Composer Pro's timeline editor to:
   - Verify notification action placement
   - Check notification names
   - Test animation timing

3. Common Issues:
   - Notification names don't match exactly
   - Entity hierarchy issues when accessing related entities
   - Timing issues with animation sequences

## References

- [WWDC23 - Build spatial experiences with RealityKit](https://developer.apple.com/videos/play/wwdc2023/10080/)
- [RealityKit Documentation](https://developer.apple.com/documentation/realitykit)
- [Reality Composer Pro Documentation](https://developer.apple.com/documentation/realitycomposer_pro)
