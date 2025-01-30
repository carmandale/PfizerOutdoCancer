# ADC Movement System Analysis

## Overview
This document analyzes movement systems from Apple's reference projects and provides recommendations for improving our ADC (Antibody-Drug Conjugate) system.

## Reference Projects Analysis

### 1. Physics Bodies Example
Key insights from `SimulatingPhysicsWithCollisionsInYourVisionOSApp`:

```swift
// Force-based movement with proper physics
struct SphereAttractionSystem: System {
    func update(context: SceneUpdateContext) {
        // Calculate forces based on position and neighbors
        let aggregateForce = calculateForces()
        // Apply forces through physics system
        sphere.addForce(aggregateForce, relativeTo: nil)
    }
}
```

Notable patterns:
- Uses proper physics forces instead of direct position manipulation
- Simple component structure with clear separation of concerns
- Physics-based time handling through simulation

### 2. Spaceship Game Example
Key insights from `CreatingASpaceshipGame`:

```swift
// Clean component separation
struct ShipFlightStateComponent: Component {
    var yaw = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
    var pitchRoll = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
}

struct ThrottleComponent: Component {
    var throttle: Float = .zero // [0,1]
}

// Physics-based movement with stabilization
final class ShipFlightSystem: System {
    func update(context: SceneUpdateContext) {
        let primaryThrust = transform.forward * throttle * strength * deltaTime
        physicsEntity.addForce(primaryThrust, relativeTo: nil)
        
        // Stabilization forces
        let assistiveThrust = -vertVelocity * shipUp * deltaTime * verticalAssistStrength
        physicsEntity.addForce(assistiveThrust, relativeTo: nil)
    }
}
```

Notable patterns:
- Split components by responsibility
- Uses physics forces with stabilization
- Consistent deltaTime usage
- Clear system organization

### 3. HappyBeam Example
Key insights from collision and movement handling:

```swift
// Event-based collision system
@MainActor
func handleCollisionStart(for event: CollisionEvents.Began) async throws {
    // Clean event validation
    guard eventHasTargets(event: event, matching: targetNames) != nil else {
        return
    }
    
    // RealityKit animation system
    let movement = FromToByAnimation<Transform>(
        name: "movement",
        from: startTransform,
        to: targetTransform,
        duration: duration,
        bindTarget: .transform
    )
}
```

Notable patterns:
- Event-based collision handling
- Uses RealityKit's animation system
- Clean state management
- Async/await for complex operations

## Recommendations for ADC System

### 1. Component Structure
Split into focused components:

```swift
struct ADCRotationComponent: Component, Codable {
    var proteinSpinSpeed: Float = 0.0
    var currentRotation: simd_quatf = .init()
}

struct ADCMovementComponent: Component, Codable {
    var speed: Float = 2.0
    var progress: Float = 0.0
    var state: MovementState
}

struct ADCTargetComponent: Component, Codable {
    var targetID: UInt64?
    var startPosition: SIMD3<Float>?
    var targetPosition: SIMD3<Float>?
}
```

### 2. Movement System
Use RealityKit's animation system for reliable movement:

```swift
final class ADCMovementSystem: System {
    static let query = EntityQuery(
        where: (
            .has(ADCMovementComponent.self) &&
            .has(ADCTargetComponent.self)
        )
    )
    
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query) {
            switch movement.state {
            case .seeking:
                handleSeeking(entity: entity, context: context)
            case .moving:
                handleMoving(entity: entity, context: context)
            case .attached:
                handleAttached(entity: entity, context: context)
            }
        }
    }
    
    private func handleMoving(entity: Entity, context: SceneUpdateContext) {
        // Use animation system for smooth movement
        let movement = FromToByAnimation<Transform>(
            name: "adcMovement",
            from: .init(scale: .one, translation: startPosition),
            to: .init(scale: .one, translation: targetPosition),
            duration: 2.0,
            bindTarget: .transform
        )
        
        entity.playAnimation(try? AnimationResource.generate(with: movement))
    }
}
```

### 3. Collision Handling
Use event-based collision system:

```swift
@MainActor
func handleADCCollision(for event: CollisionEvents.Began) async throws {
    guard let adcEntity = eventHasTarget(event: event, matching: "ADC"),
          let attachPoint = eventHasTarget(event: event, matching: "AttachmentPoint") else {
        return
    }
    
    // Handle attachment with animation
    await attachADC(adcEntity, to: attachPoint)
}
```

### 4. State Management
Clean state transitions in the system:

```swift
private func handleStateTransition(entity: Entity, from: ADCState, to: ADCState) {
    switch (from, to) {
    case (.seeking, .moving):
        startMovementAnimation(entity)
    case (.moving, .attached):
        startAttachmentAnimation(entity)
    default:
        break
    }
}
```

## Benefits of Implementation

1. **Improved Reliability**
   - More predictable movement using RealityKit's animation system
   - Better collision detection with event-based system
   - Proper physics integration

2. **Better Maintainability**
   - Clear separation of concerns
   - Focused components
   - Simpler state management

3. **Performance**
   - Optimized animation system usage
   - Efficient component queries
   - Better memory management

4. **Debugging**
   - Clearer state transitions
   - Better error handling
   - More precise control points

## Next Steps

1. Implement component separation
2. Convert movement to animation-based system
3. Set up event-based collision handling
4. Add proper state management
5. Test and validate improvements 