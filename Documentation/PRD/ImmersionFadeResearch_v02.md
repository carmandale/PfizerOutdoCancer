# Movement-Based Scene Fading System

**Product Requirements Document**

**Version 1.0**  
**Date: March 26, 2025**

## 1. Introduction

### 1.1 Overview

This document outlines the requirements and implementation details for a movement-based fading system in visionOS 2. The system will gradually fade a 3D scene based on user movement away from an origin point, improving real-world awareness while maintaining immersion.

### 1.2 Problem Statement

In mixed immersion spaces, when digital content occludes most of the real world, user movement can create safety concerns. While visionOS provides some built-in fading behavior, it lacks the specific distance-based fading and origin reset capabilities required for our application.

### 1.3 Goals

- Create a smooth, radius-based fading system that reduces scene opacity when users move away from an origin point
- Restore full opacity when movement stops, setting a new origin point
- Implement as a dedicated RealityKit system following ECS architecture principles
- Ensure transitions are natural and not jarring

## 2. Requirements

### 2.1 Functional Requirements

- **FR1**: The system shall detect user movement based on device position and velocity
- **FR2**: The system shall smoothly reduce scene opacity as the user moves beyond a configurable distance threshold
- **FR3**: The system shall restore full opacity when user movement stops
- **FR4**: The system shall reset the origin point when user stops moving
- **FR5**: All fading transitions shall be smooth and gradual
- **FR6**: The system shall optimize performance by reducing update frequency while maintaining visual smoothness

### 2.2 Technical Requirements

- **TR1**: Implement as a dedicated RealityKit ECS system
- **TR2**: Use ARKit's device tracking for position data
- **TR3**: Support configurable parameters for fading distances and thresholds
- **TR4**: Ensure efficient per-frame updates with minimal performance impact

### 2.3 Performance Requirements

- **PR1**: The system shall maintain 90 FPS during normal operation
- **PR2**: Movement detection shall be smooth and free from jitter
- **PR3**: Opacity transitions shall complete within configurable timeframes
- **PR4**: The system shall optimize CPU usage by processing updates at a reduced frequency (15Hz) while maintaining visual smoothness

## 3. Technical Design

### 3.1 Architecture Overview

The implementation will follow RealityKit's Entity Component System (ECS) architecture with performance optimizations:

1. A custom `MovementFadingComponent` will mark entities for fading and store configuration
2. A dedicated `MovementFadingSystem` will handle movement detection and opacity adjustments, using frame skipping for performance
3. Extension methods on `Entity` will facilitate smooth opacity transitions

This design separates concerns, with each part having a specific responsibility:
- Component: Configuration and state
- System: Logic and processing with optimized update frequency
- Extensions: Utility functions

The system uses a hybrid approach that maintains ECS architecture while reducing processing frequency to optimize performance.

### 3.2 Component Design

```swift
/// Marks entities that should fade based on user movement
public struct MovementFadingComponent: Component, Codable {
    // Configuration
    /// Distance in meters when fading begins
    public var fadeRadiusStart: Float = 1.0
    
    /// Distance in meters when fully faded
    public var fadeRadiusEnd: Float = 2.0
    
    /// Minimum opacity value when fully faded
    public var minOpacity: Float = 0.0
    
    /// Maximum opacity value when not faded
    public var maxOpacity: Float = 1.0
    
    /// Threshold in meters/second to detect movement
    public var velocityThreshold: Float = 0.1
    
    /// Duration in seconds for opacity transitions
    public var transitionDuration: TimeInterval = 0.5
    
    // Internal state - not meant to be modified directly
    var origin: SIMD3<Float> = .zero
    var currentOpacity: Float = 1.0
    var isMoving: Bool = false
    var initialized: Bool = false
    
    /// Default initializer with standard configuration
    public init() {}
    
    /// Initializer with custom parameters
    public init(
        fadeRadiusStart: Float = 1.0,
        fadeRadiusEnd: Float = 2.0,
        minOpacity: Float = 0.0,
        maxOpacity: Float = 1.0,
        velocityThreshold: Float = 0.1,
        transitionDuration: TimeInterval = 0.5
    ) {
        self.fadeRadiusStart = fadeRadiusStart
        self.fadeRadiusEnd = fadeRadiusEnd
        self.minOpacity = minOpacity
        self.maxOpacity = maxOpacity
        self.velocityThreshold = velocityThreshold
        self.transitionDuration = transitionDuration
    }
}
```

### 3.3 System Implementation

```swift
import Foundation
import RealityKit
import ARKit

/// System that handles movement-based fading of entities in a RealityKit scene
@MainActor
public class MovementFadingSystem: System {
    // Query for entities with the fading component
    static let query = EntityQuery(where: .has(MovementFadingComponent.self))
    
    // Reference to the app model for accessing tracking data
    private static var sharedAppModel: AppModel?
    
    // Movement tracking state
    private var previousPosition: SIMD3<Float>?
    private var previousTime: TimeInterval = 0
    private var velocitySmoothed: Float = 0.0
    
    // Smoothing factor for velocity (0-1, higher = less smoothing)
    private let velocitySmoothingFactor: Float = 0.3
    
    // Adaptive frame skipping for performance optimization
    private var frameCounter: Int = 0
    private var adaptiveFrameSkip: Int = 6  // Start with 15Hz at 90fps
    private var lastSignificantMovement: TimeInterval = 0
    
    // Batch processing for opacity changes
    private var pendingOpacityChanges: [(Entity, Float)] = []
    
    /// Sets the app model reference to access tracking data
    /// - Parameter appModel: The application model that contains tracking providers
    internal static func setAppModel(_ appModel: AppModel) {
        sharedAppModel = appModel
    }
    
    /// Required initializer for RealityKit systems
    /// - Parameter scene: The scene this system is added to
    public required init(scene: RealityKit.Scene) {
        previousTime = Date().timeIntervalSinceReferenceDate
        lastSignificantMovement = previousTime
    }
    
    /// Called each frame to update entity opacity based on movement
    /// - Parameter context: The scene update context providing frame timing and entity access
    public func update(context: SceneUpdateContext) {
        // Adaptive performance optimization: only process at reduced frequency
        frameCounter += 1
        if frameCounter < adaptiveFrameSkip {
            return
        }
        frameCounter = 0
        
        // Get current time using standard Swift API
        let currentTime = Date().timeIntervalSinceReferenceDate
        
        // Get device tracking data
        guard let appModel = Self.sharedAppModel,
              case .running = appModel.trackingManager.worldTrackingProvider.state,
              let deviceAnchor = appModel.trackingManager.worldTrackingProvider.queryDeviceAnchor(atTimestamp: currentTime) else {
            return
        }
        
        let devicePosition = deviceAnchor.originFromAnchorTransform.translation()
        let deltaTime = Float(currentTime - previousTime)
        
        // Skip tiny time increments to avoid division issues
        guard deltaTime > 0.001 else {
            return
        }
        
        // Calculate instantaneous velocity with optimization for performance
        var instantVelocity: Float = 0.0
        if let prevPos = previousPosition {
            let distanceSq = simd_distance_squared(devicePosition, prevPos)
            instantVelocity = sqrt(distanceSq) / deltaTime
        }
        
        // Apply exponential smoothing to velocity using existing math utilities
        velocitySmoothed = ADCMovementSystem.mix(velocitySmoothed, instantVelocity, t: velocitySmoothingFactor)
        
        // Update adaptive frame skip rate based on movement
        updateAdaptiveFrameSkip(currentTime: currentTime)
        
        // Early exit if velocity is well below threshold
        if velocitySmoothed < 0.02 {  // Hard minimum
            previousPosition = devicePosition
            previousTime = currentTime
            return  // Skip entity processing entirely
        }
        
        // Clear previous batch
        pendingOpacityChanges.removeAll()
        
        // Process each entity with the fading component - CRITICAL: Must specify updatingSystemWhen
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            processEntity(entity, devicePosition: devicePosition)
        }
        
        // Apply batched opacity changes for better performance
        if !pendingOpacityChanges.isEmpty {
            Task { @MainActor in
                for (entity, opacity) in pendingOpacityChanges {
                    var fadingComponent = entity.components[MovementFadingComponent.self]!
                    fadingComponent.currentOpacity = opacity
                    entity.components[MovementFadingComponent.self] = fadingComponent
                    
                    await entity.fadeOpacity(to: opacity, 
                                     duration: fadingComponent.transitionDuration,
                                     timing: .easeInOut)
                }
            }
        }
        
        previousPosition = devicePosition
        previousTime = currentTime
    }
    
    /// Updates the adaptive frame skip rate based on recent movement
    private func updateAdaptiveFrameSkip(currentTime: TimeInterval) {
        let timeSinceMovement = currentTime - lastSignificantMovement
        
        // Reduce frequency when idle
        if velocitySmoothed < 0.05 {
            if timeSinceMovement > 1.0 {
                adaptiveFrameSkip = min(18, adaptiveFrameSkip + 1)  // Up to ~5Hz when idle
            }
        } else {
            adaptiveFrameSkip = 6  // Back to 15Hz when moving
            lastSignificantMovement = currentTime
        }
    }
    
    /// Processes a single entity for movement fading
    /// - Parameters:
    ///   - entity: The entity to process
    ///   - devicePosition: Current device position in world space
    private func processEntity(_ entity: Entity, devicePosition: SIMD3<Float>) {
        guard var fadingComponent = entity.components[MovementFadingComponent.self] else { return }
        
        // Initialize if needed
        if !fadingComponent.initialized {
            fadingComponent.origin = devicePosition
            fadingComponent.initialized = true
            entity.components[MovementFadingComponent.self] = fadingComponent
            return
        }
        
        // Determine movement state with hysteresis for stability
        let wasMoving = fadingComponent.isMoving
        if fadingComponent.isMoving {
            // Require lower velocity to stop (prevents flickering)
            fadingComponent.isMoving = velocitySmoothed > (fadingComponent.velocityThreshold * 0.8)
        } else {
            // Require higher velocity to start (prevents accidental triggers)
            fadingComponent.isMoving = velocitySmoothed > fadingComponent.velocityThreshold
        }
        
        // Handle origin reset when stopping
        if wasMoving && !fadingComponent.isMoving {
            fadingComponent.origin = devicePosition
            entity.components[MovementFadingComponent.self] = fadingComponent
        }
        
        // Performance optimization: Use squared distances for faster comparisons
        let distanceSquared = simd_distance_squared(devicePosition, fadingComponent.origin)
        let startRadiusSquared = fadingComponent.fadeRadiusStart * fadingComponent.fadeRadiusStart
        
        // Early exit if entity hasn't moved past start threshold
        if !fadingComponent.isMoving || distanceSquared <= startRadiusSquared {
            // Only restore opacity if needed
            if fadingComponent.currentOpacity < fadingComponent.maxOpacity {
                pendingOpacityChanges.append((entity, fadingComponent.maxOpacity))
            }
            return
        }
        
        // Only compute target opacity if movement state and distance warrant it
        let endRadiusSquared = fadingComponent.fadeRadiusEnd * fadingComponent.fadeRadiusEnd
        
        // Calculate target opacity with smooth transition
        var targetOpacity: Float
        
        if distanceSquared >= endRadiusSquared {
            targetOpacity = fadingComponent.minOpacity
        } else {
            // Need sqrt for accurate interpolation
            let distance = sqrt(distanceSquared)
            
            // Use existing math utilities from your project
            let t = ADCMovementSystem.smoothstep(
                fadingComponent.fadeRadiusStart,
                fadingComponent.fadeRadiusEnd,
                distance
            )
            targetOpacity = ADCMovementSystem.mix(fadingComponent.maxOpacity, fadingComponent.minOpacity, t: t)
        }
        
        // Only update if opacity would change significantly
        if abs(targetOpacity - fadingComponent.currentOpacity) > 0.01 {
            pendingOpacityChanges.append((entity, targetOpacity))
        }
    }
}
```

### 3.4 Entity Extensions

```swift
import RealityKit

extension Entity {
    /// Gets the current opacity of the entity
    public var opacity: Float {
        get {
            return components[OpacityComponent.self]?.opacity ?? 1.0
        }
        set {
            var opacityComponent = components[OpacityComponent.self] ?? OpacityComponent()
            opacityComponent.opacity = newValue
            components[OpacityComponent.self] = opacityComponent
        }
    }
    
    /// Fades the entity's opacity to the target value over time
    /// - Parameters:
    ///   - targetOpacity: The final opacity value (0.0-1.0)
    ///   - duration: Duration of the fade in seconds
    ///   - delay: Delay before starting the animation
    ///   - timing: Animation timing function
    ///   - waitForCompletion: Whether to wait for animation completion
    /// - Returns: Optional Task that completes when the animation finishes
    @discardableResult
    public func fadeOpacity(
        to targetOpacity: Float,
        duration: Float = 0.5,
        delay: Float = 0,
        timing: AnimationTimingFunction = .easeInOut,
        waitForCompletion: Bool = false
    ) -> Task<Void, Never>? {
        // Skip animation for very short durations or no change
        if duration < 0.01 || abs(self.opacity - targetOpacity) < 0.01 {
            self.opacity = targetOpacity
            return nil
        }
        
        if waitForCompletion {
            return Task {
                try? await self.setOpacity(targetOpacity, duration: duration, delay: delay, timing: timing)
            }
        } else {
            Task {
                try? await self.setOpacity(targetOpacity, duration: duration, delay: delay, timing: timing)
            }
            return nil
        }
    }
    
    private func setOpacity(_ opacity: Float, duration: Float, delay: Float, timing: AnimationTimingFunction) async throws {
        // Ensure opacity component exists
        var opacityComponent = components[OpacityComponent.self] ?? OpacityComponent()
        components[OpacityComponent.self] = opacityComponent
        
        // Create and run the animation
        var animation = OpacityAnimation(to: opacity, duration: TimeInterval(duration), timing: timing)
        if delay > 0 {
            animation.delay = TimeInterval(delay)
        }
        await self.animateInPlace(animation)
    }
}
```

## 4. Implementation Guide

### 4.1 Prerequisites

- visionOS 2 development environment
- Existing app using RealityKit and mixed immersion
- Access to ARKit world tracking data

### 4.2 Implementation Steps

#### Step 1: Add Component and System Files

Create two new Swift files:
1. `MovementFadingComponent.swift` - For the component definition
2. `MovementFadingSystem.swift` - For the system implementation

#### Step 2: Add Entity Extensions

Create `Entity+Opacity.swift` for the opacity extension methods.

#### Step 3: Register and Configure the System

In your app initialization code, typically in your immersive space setup:

```swift
import SwiftUI
import RealityKit

struct MyImmersiveView: View {
    @StateObject private var appModel = AppModel()
    
    var body: some View {
        RealityView { content in
            // Create your root entity
            let rootEntity = Entity()
            
            // Add content to the root entity
            // ...
            
            // Add movement fading component
            var fadingComponent = MovementFadingComponent()
            // Customize parameters if needed
            fadingComponent.fadeRadiusStart = 0.8
            fadingComponent.fadeRadiusEnd = 2.0
            fadingComponent.transitionDuration = 0.4  // Faster transitions (optional)
            rootEntity.components[MovementFadingComponent.self] = fadingComponent
            
            // Add to content
            content.add(rootEntity)
            
            // Register systems with the content's scene
            if let scene = content.entities.scene {
                // Register the movement fading system
                scene.systems.add(MovementFadingSystem.self)
                MovementFadingSystem.setAppModel(appModel)
                
                // Register other systems
                // ...
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Start tracking if needed
            appModel.startTracking()
        }
    }
}
```

#### Step 4: Adapt AppModel for Tracking Access

Ensure your AppModel provides access to world tracking:

```swift
@MainActor
class AppModel: ObservableObject {
    let trackingManager = TrackingManager()
    
    func startTracking() {
        trackingManager.startTracking()
    }
}

class TrackingManager {
    let worldTrackingProvider = WorldTrackingProvider()
    
    func startTracking() {
        worldTrackingProvider.startTracking()
    }
}
```

## 5. Testing

### 5.1 Key Test Scenarios

1. **Movement Detection**
   - Verify that movement is properly detected when user walks
   - Confirm that small head movements don't trigger fading

2. **Fading Behavior**
   - Verify smooth fading starts at fadeRadiusStart
   - Verify reaches minimum opacity at fadeRadiusEnd
   - Confirm transitions are smooth and not jarring

3. **Origin Reset**
   - Verify origin is reset when user stops moving
   - Confirm opacity returns to maximum after stopping

4. **Performance**
   - Test on actual device to ensure 90 FPS is maintained
   - Verify no stuttering during transitions
   - Confirm CPU usage is reduced compared to per-frame processing
   - Test different framesPerCheck values to find optimal balance

### 5.2 Testing Process

1. Build and run on Vision Pro device (simulator has limitations for movement testing)
2. Create a test immersive space with large, easily visible content
3. Move around the physical space while monitoring opacity changes
4. Test edge cases (quick movements, stopping at different distances)

## 6. Best Practices

### 6.1 SwiftUI Integration

- Use `RealityView` for integrating RealityKit content
- Manage state with proper ObservableObject patterns
- Use `.ignoresSafeArea()` for immersive spaces

### 6.2 RealityKit ECS Patterns

- Always make components `Codable` - this is required for proper serialization 
- Keep components simple, primarily for data storage
- Implement logic in systems, not components
- Always include `updatingSystemWhen: .rendering` in `context.entities(matching:)` calls
- Use `Date().timeIntervalSinceReferenceDate` instead of `CACurrentMediaTime()`
- Reuse existing math utilities when available instead of duplicating them
- Process entities in batches when possible to reduce component updates
- Implement adaptive frame skipping for optimal performance balance
- Use `simd_distance_squared` instead of `length()` when possible for performance
- Only perform square root calculations when absolutely necessary

### 6.3 System Registration

- Register systems centrally in your app's initialization code
- Use the simple `registerSystem()` method without parameters
- Set up any dependencies (like AppModel references) before using the system

### 6.4 Performance Optimizations

- **Adaptive Frame Skipping**: Dynamically adjust processing frequency based on movement
- **Batch Processing**: Group similar component updates to reduce overhead
- **Early Exits**: Skip processing when no significant changes are needed
- **Squared Distances**: Use squared distances for comparisons to avoid square roots
- **Movement Hysteresis**: Implement different thresholds for starting/stopping movement
- **Targeted Updates**: Only update entity components when values change significantly

### 6.5 visionOS 2 Guidelines

- Test on physical device for actual movement behavior
- Ensure smooth transitions for better user experience
- Follow privacy guidelines for tracking data
- Consider accessibility implications for users with movement limitations

## 7. References

### 7.1 Apple Documentation

- [RealityKit Documentation](https://developer.apple.com/documentation/realitykit)
- [Entity Component System in RealityKit](https://developer.apple.com/documentation/realitykit/entity)
- [ARKit in visionOS](https://developer.apple.com/documentation/arkit/arkit-in-visionos)
- [Immersive Spaces in visionOS](https://developer.apple.com/documentation/visionos/immersiveSpace)

### 7.2 Sample Code Files

Below is a consolidated set of files for implementation:

**MovementFadingComponent.swift**
```swift
import Foundation
import RealityKit

/// Marks entities that should fade based on user movement
public struct MovementFadingComponent: Component, Codable {
    // Configuration
    /// Distance in meters when fading begins
    public var fadeRadiusStart: Float = 1.0
    
    /// Distance in meters when fully faded
    public var fadeRadiusEnd: Float = 2.0
    
    /// Minimum opacity value when fully faded
    public var minOpacity: Float = 0.0
    
    /// Maximum opacity value when not faded
    public var maxOpacity: Float = 1.0
    
    /// Threshold in meters/second to detect movement
    public var velocityThreshold: Float = 0.1
    
    /// Duration in seconds for opacity transitions
    public var transitionDuration: TimeInterval = 0.5
    
    // Internal state - not meant to be modified directly
    var origin: SIMD3<Float> = .zero
    var currentOpacity: Float = 1.0
    var isMoving: Bool = false
    var initialized: Bool = false
    
    /// Default initializer with standard configuration
    public init() {}
    
    /// Initializer with custom parameters
    public init(
        fadeRadiusStart: Float = 1.0,
        fadeRadiusEnd: Float = 2.0,
        minOpacity: Float = 0.0,
        maxOpacity: Float = 1.0,
        velocityThreshold: Float = 0.1,
        transitionDuration: TimeInterval = 0.5
    ) {
        self.fadeRadiusStart = fadeRadiusStart
        self.fadeRadiusEnd = fadeRadiusEnd
        self.minOpacity = minOpacity
        self.maxOpacity = maxOpacity
        self.velocityThreshold = velocityThreshold
        self.transitionDuration = transitionDuration
    }
}
```

**MovementFadingSystem.swift**
```swift
import Foundation
import RealityKit
import ARKit

/// System that handles movement-based fading of entities in a RealityKit scene
@MainActor
public class MovementFadingSystem: System {
    // Query for entities with the fading component
    static let query = EntityQuery(where: .has(MovementFadingComponent.self))
    
    // Reference to the app model for accessing tracking data
    private static var sharedAppModel: AppModel?
    
    // Movement tracking state
    private var previousPosition: SIMD3<Float>?
    private var previousTime: TimeInterval = 0
    private var velocitySmoothed: Float = 0.0
    
    // Smoothing factor for velocity (0-1, higher = less smoothing)
    private let velocitySmoothingFactor: Float = 0.3
    
    // Adaptive frame skipping for performance optimization
    private var frameCounter: Int = 0
    private var adaptiveFrameSkip: Int = 6  // Start with 15Hz at 90fps
    private var lastSignificantMovement: TimeInterval = 0
    
    // Batch processing for opacity changes
    private var pendingOpacityChanges: [(Entity, Float)] = []
    
    /// Sets the app model reference to access tracking data
    /// - Parameter appModel: The application model that contains tracking providers
    internal static func setAppModel(_ appModel: AppModel) {
        sharedAppModel = appModel
    }
    
    /// Required initializer for RealityKit systems
    /// - Parameter scene: The scene this system is added to
    public required init(scene: RealityKit.Scene) {
        previousTime = Date().timeIntervalSinceReferenceDate
        lastSignificantMovement = previousTime
    }
    
    /// Called each frame to update entity opacity based on movement
    /// - Parameter context: The scene update context providing frame timing and entity access
    public func update(context: SceneUpdateContext) {
        // Adaptive performance optimization: only process at reduced frequency
        frameCounter += 1
        if frameCounter < adaptiveFrameSkip {
            return
        }
        frameCounter = 0
        
        // Get current time using standard Swift API
        let currentTime = Date().timeIntervalSinceReferenceDate
        
        // Get device tracking data
        guard let appModel = Self.sharedAppModel,
              case .running = appModel.trackingManager.worldTrackingProvider.state,
              let deviceAnchor = appModel.trackingManager.worldTrackingProvider.queryDeviceAnchor(atTimestamp: currentTime) else {
            return
        }
        
        let devicePosition = deviceAnchor.originFromAnchorTransform.translation()
        let deltaTime = Float(currentTime - previousTime)
        
        // Skip tiny time increments to avoid division issues
        guard deltaTime > 0.001 else {
            return
        }
        
        // Calculate instantaneous velocity with optimization for performance
        var instantVelocity: Float = 0.0
        if let prevPos = previousPosition {
            let distanceSq = simd_distance_squared(devicePosition, prevPos)
            instantVelocity = sqrt(distanceSq) / deltaTime
        }
        
        // Apply exponential smoothing to velocity using existing math utilities
        velocitySmoothed = ADCMovementSystem.mix(velocitySmoothed, instantVelocity, t: velocitySmoothingFactor)
        
        // Update adaptive frame skip rate based on movement
        updateAdaptiveFrameSkip(currentTime: currentTime)
        
        // Early exit if velocity is well below threshold
        if velocitySmoothed < 0.02 {  // Hard minimum
            previousPosition = devicePosition
            previousTime = currentTime
            return  // Skip entity processing entirely
        }
        
        // Clear previous batch
        pendingOpacityChanges.removeAll()
        
        // Process each entity with the fading component - CRITICAL: Must specify updatingSystemWhen
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            processEntity(entity, devicePosition: devicePosition)
        }
        
        // Apply batched opacity changes for better performance
        if !pendingOpacityChanges.isEmpty {
            Task { @MainActor in
                for (entity, opacity) in pendingOpacityChanges {
                    var fadingComponent = entity.components[MovementFadingComponent.self]!
                    fadingComponent.currentOpacity = opacity
                    entity.components[MovementFadingComponent.self] = fadingComponent
                    
                    await entity.fadeOpacity(to: opacity, 
                                     duration: fadingComponent.transitionDuration,
                                     timing: .easeInOut)
                }
            }
        }
        
        previousPosition = devicePosition
        previousTime = currentTime
    }
    
    /// Updates the adaptive frame skip rate based on recent movement
    private func updateAdaptiveFrameSkip(currentTime: TimeInterval) {
        let timeSinceMovement = currentTime - lastSignificantMovement
        
        // Reduce frequency when idle
        if velocitySmoothed < 0.05 {
            if timeSinceMovement > 1.0 {
                adaptiveFrameSkip = min(18, adaptiveFrameSkip + 1)  // Up to ~5Hz when idle
            }
        } else {
            adaptiveFrameSkip = 6  // Back to 15Hz when moving
            lastSignificantMovement = currentTime
        }
    }
    
    /// Processes a single entity for movement fading
    /// - Parameters:
    ///   - entity: The entity to process
    ///   - devicePosition: Current device position in world space
    private func processEntity(_ entity: Entity, devicePosition: SIMD3<Float>) {
        guard var fadingComponent = entity.components[MovementFadingComponent.self] else { return }
        
        // Initialize if needed
        if !fadingComponent.initialized {
            fadingComponent.origin = devicePosition
            fadingComponent.initialized = true
            entity.components[MovementFadingComponent.self] = fadingComponent
            return
        }
        
        // Determine movement state with hysteresis for stability
        let wasMoving = fadingComponent.isMoving
        if fadingComponent.isMoving {
            // Require lower velocity to stop (prevents flickering)
            fadingComponent.isMoving = velocitySmoothed > (fadingComponent.velocityThreshold * 0.8)
        } else {
            // Require higher velocity to start (prevents accidental triggers)
            fadingComponent.isMoving = velocitySmoothed > fadingComponent.velocityThreshold
        }
        
        // Handle origin reset when stopping
        if wasMoving && !fadingComponent.isMoving {
            fadingComponent.origin = devicePosition
            entity.components[MovementFadingComponent.self] = fadingComponent
        }
        
        // Performance optimization: Use squared distances for faster comparisons
        let distanceSquared = simd_distance_squared(devicePosition, fadingComponent.origin)
        let startRadiusSquared = fadingComponent.fadeRadiusStart * fadingComponent.fadeRadiusStart
        
        // Early exit if entity hasn't moved past start threshold
        if !fadingComponent.isMoving || distanceSquared <= startRadiusSquared {
            // Only restore opacity if needed
            if fadingComponent.currentOpacity < fadingComponent.maxOpacity {
                pendingOpacityChanges.append((entity, fadingComponent.maxOpacity))
            }
            return
        }
        
        // Only compute target opacity if movement state and distance warrant it
        let endRadiusSquared = fadingComponent.fadeRadiusEnd * fadingComponent.fadeRadiusEnd
        
        // Calculate target opacity with smooth transition
        var targetOpacity: Float
        
        if distanceSquared >= endRadiusSquared {
            targetOpacity = fadingComponent.minOpacity
        } else {
            // Need sqrt for accurate interpolation
            let distance = sqrt(distanceSquared)
            
            // Use existing math utilities from your project
            let t = ADCMovementSystem.smoothstep(
                fadingComponent.fadeRadiusStart,
                fadingComponent.fadeRadiusEnd,
                distance
            )
            targetOpacity = ADCMovementSystem.mix(fadingComponent.maxOpacity, fadingComponent.minOpacity, t: t)
        }
        
        // Only update if opacity would change significantly
        if abs(targetOpacity - fadingComponent.currentOpacity) > 0.01 {
            pendingOpacityChanges.append((entity, targetOpacity))
        }
    }
}
```

**Entity+Opacity.swift**
```swift
import RealityKit

extension Entity {
    /// Gets the current opacity of the entity
    public var opacity: Float {
        get {
            return components[OpacityComponent.self]?.opacity ?? 1.0
        }
        set {
            var opacityComponent = components[OpacityComponent.self] ?? OpacityComponent()
            opacityComponent.opacity = newValue
            components[OpacityComponent.self] = opacityComponent
        }
    }
    
    /// Fades the entity's opacity to the target value over time
    /// - Parameters:
    ///   - targetOpacity: The final opacity value (0.0-1.0)
    ///   - duration: Duration of the fade in seconds
    ///   - delay: Delay before starting the animation
    ///   - timing: Animation timing function
    ///   - waitForCompletion: Whether to wait for animation completion
    /// - Returns: Optional Task that completes when the animation finishes
    @discardableResult
    public func fadeOpacity(
        to targetOpacity: Float,
        duration: Float = 0.5,
        delay: Float = 0,
        timing: AnimationTimingFunction = .easeInOut,
        waitForCompletion: Bool = false
    ) -> Task<Void, Never>? {
        // Skip animation for very short durations or no change
        if duration < 0.01 || abs(self.opacity - targetOpacity) < 0.01 {
            self.opacity = targetOpacity
            return nil
        }
        
        if waitForCompletion {
            return Task {
                try? await self.setOpacity(targetOpacity, duration: duration, delay: delay, timing: timing)
            }
        } else {
            Task {
                try? await self.setOpacity(targetOpacity, duration: duration, delay: delay, timing: timing)
            }
            return nil
        }
    }
    
    private func setOpacity(_ opacity: Float, duration: Float, delay: Float, timing: AnimationTimingFunction) async throws {
        // Ensure opacity component exists
        var opacityComponent = components[OpacityComponent.self] ?? OpacityComponent()
        components[OpacityComponent.self] = opacityComponent
        
        // Create and run the animation
        var animation = OpacityAnimation(to: opacity, duration: TimeInterval(duration), timing: timing)
        if delay > 0 {
            animation.delay = TimeInterval(delay)
        }
        await self.animateInPlace(animation)
    }
}
```

## 8. Conclusion

This implementation provides a smooth, radius-based fading system that enhances user safety while maintaining immersion. By following RealityKit ECS best practices, it efficiently manages scene opacity based on movement, with robust movement detection and natural transitions. The system is configurable, well-documented, and designed to be implemented by junior developers with minimal friction.