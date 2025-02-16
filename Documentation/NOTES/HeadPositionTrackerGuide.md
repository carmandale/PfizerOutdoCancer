# HeadPositionTracker Implementation Guide

## Overview
The `HeadPositionTracker` provides easy positioning of 3D content in front of the user in visionOS apps. It handles world tracking and device transform calculations automatically.

## Basic Implementation

### 1. Add HeadTracker to Your View

```swift
struct YourImmersiveView: View {
    @State private var headTracker = HeadPositionTracker() // Changed from @StateObject to @State
    @State var yourEntity: Entity? = nil
    // ... rest of your view code
}
```

### 2. Position Your Entity
There are two ways to position your entity:

#### Option A: Direct Call in RealityView
```swift
var body: some View {
    RealityView { content in
        // Setup your entity
        let entity = Entity()
        self.yourEntity = entity
        content.add(entity)
        // Position the entity in front of the user
        headTracker.positionEntityInFrontOfUser(yourEntity)
    }
}
```

#### Option B: Separate Function (Recommended)
```swift
struct YourImmersiveView: View {
    private func positionEntity() {
        headTracker.positionEntityInFrontOfUser(yourEntity)
    }
    
    var body: some View {
        RealityView { content in
            // Setup your entity
            let entity = Entity()
            self.yourEntity = entity
            content.add(entity)
            
            positionEntity()
        }
    }
}
```

## Advanced Usage

### Custom Z-Offset
You can specify how far in front of the user to position the entity:
```swift
// Position 2 meters in front of the user
headTracker.positionEntityInFrontOfUser(yourEntity, zOffset: -2.0)
```

### Multiple Entities
You can position multiple entities at different distances:
```swift
// Position different entities at different distances
headTracker.positionEntityInFrontOfUser(backgroundEntity, zOffset: -3.0)
headTracker.positionEntityInFrontOfUser(middleEntity, zOffset: -2.0)
headTracker.positionEntityInFrontOfUser(foregroundEntity, zOffset: -1.0)
```

## Initialization and Timing

### Important: Proper Initialization
The `HeadPositionTracker` requires proper initialization before it can be used to position entities. Here's what you need to know:

1. **Async Initialization**: Always await the initialization before positioning entities:
```swift
RealityView { content in
    Task {
        try? await headTracker.ensureInitialized()
        // Only position entities after initialization
        positionEntity()
    }
}
```

2. **World Tracking Provider**: The tracker needs time for the ARKit world tracking provider to fully initialize. The `ensureInitialized()` function now includes a small delay to ensure the tracking system is ready.

3. **Common Issues**:
   - If you see the error "The device_anchor can only be queried when the world tracking provider is running", it means you're trying to position entities before the tracking system is fully initialized.
   - Always position entities after `ensureInitialized()` completes.

4. **Best Practice for Complex Views**:
```swift
RealityView { content in
    // Capture content reference for async use
    let contentRef = content
    
    Task {
        do {
            // First initialize tracking
            try await headTracker.ensureInitialized()
            
            // Then set up your entities
            // ... entity setup code ...
            
            // Finally position after everything is ready
            positionEntity()
        } catch {
            print("❌ Error initializing head tracking: \(error)")
        }
    }
}
```

### Troubleshooting
- If entities are not positioning correctly, check that you're awaiting `ensureInitialized()`
- The initialization includes a 500ms delay to ensure world tracking is fully running
- Use proper error handling to catch and handle initialization failures
- For views with multiple entities, set up all entities before positioning them

## Best Practices

1. **State Usage**: Use `@State` for the tracker in your views (replaces previous @StateObject usage).
   ```swift
   @State private var headTracker = HeadPositionTracker()
   ```

2. **Entity State**: Keep your entities as `@State` variables to ensure proper updates.
   ```swift
   @State var mainEntity: Entity? = nil
   ```

3. **Environment Usage**: If sharing the tracker across multiple views, use `.environment()` instead of `.environmentObject()`:
   ```swift
   // In parent view:
   .environment(headTracker)
   
   // In child views:
   @Environment(HeadPositionTracker.self) private var headTracker
   ```

4. **Initial Positioning**: Position entities during initial setup in the RealityView.

5. **Error Handling**: The tracker handles its own error cases, but you may want to observe its state in more complex implementations.

## Notes
- Negative z-offset values move the entity forward (closer to the user)
- Positive z-offset values move the entity backward (away from the user)
- The default z-offset is -1.0 meters
- World tracking support is checked automatically during initialization

## Example Implementation
```swift
struct ExampleImmersiveView: View {
    @State private var headTracker = HeadPositionTracker()
    @State var mainEntity: Entity? = nil
    
    private func positionContent() {
        headTracker.positionEntityInFrontOfUser(mainEntity)
    }
    
    var body: some View {
        RealityView { content in
            let entity = ModelEntity()
            self.mainEntity = entity
            content.add(entity)
            
            positionContent()
        }
    }
}
