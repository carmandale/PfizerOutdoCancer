# Refined Head Position Control PRD

## Overview
The goal is to enhance control over head-based positioning within immersive scenes by enabling explicit on-demand updates. Currently, the `PositioningSystem` automatically updates an entity's position when the `needsPositioning` flag in its `PositioningComponent` is true. After an update, the flag resets to false. By introducing explicit control, developers can choose when any immersive view (e.g., Intro, Lab, AttackCancer) should re-evaluate and update its positioning relative to the user's head position.

## Current Behavior
- **Automatic Update:**  
  - Entities with a `PositioningComponent` having `needsPositioning` set to true are repositioned according to the user's current head position.
  - Once updated, the flag resets to false, preventing continuous updates.
  
- **Usage in the Codebase:**  
  - *IntroViewModel.swift* contains a `refreshPosition()` method that calculates the new position based on a device anchor.
  - *LabViewModel.swift* and *AttackCancerViewModel.swift* set up their root entities with a `PositioningComponent` but currently rely on the initial setup, missing an explicit repositioning trigger.

## Proposed Changes

### 1. New API for Explicit Positioning Control
Introduce an extension on `Entity` to allow explicit triggering of head repositioning:

```swift
extension Entity {
    func checkHeadPosition(animated: Bool = false, duration: TimeInterval = 0.5) {
        guard var positioningComponent = components[PositioningComponent.self] else { return }
        positioningComponent.needsPositioning = true
        positioningComponent.shouldAnimate = animated
        positioningComponent.animationDuration = animated ? duration : 0.0
        components[PositioningComponent.self] = positioningComponent
    }
}
```

### 2. Modified PositioningSystem
Update the system to respect on-demand positioning:

```swift
public func update(context: SceneUpdateContext) {
    guard let appModel = Self.sharedAppModel,
          case .running = appModel.trackingManager.worldTrackingProvider.state,
          let deviceAnchor = appModel.trackingManager.worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else {
        return
    }
    
    for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
        guard var positioningComponent = entity.components[PositioningComponent.self],
              positioningComponent.needsPositioning else { continue }
        
        let deviceTransform = deviceAnchor.originFromAnchorTransform
        let translation = deviceTransform.translation()
        let targetPosition = SIMD3<Float>(
            translation.x + positioningComponent.offsetX,
            translation.y + positioningComponent.offsetY,
            translation.z + positioningComponent.offsetZ
        )
        
        if positioningComponent.shouldAnimate {
            Task {
                await entity.animatePosition(
                    to: targetPosition,
                    duration: positioningComponent.animationDuration,
                    timing: .easeInOut,
                    waitForCompletion: false
                )
                positioningComponent.needsPositioning = false
                entity.components[PositioningComponent.self] = positioningComponent
            }
        } else {
            entity.setPosition(targetPosition, relativeTo: nil)
            positioningComponent.needsPositioning = false
            entity.components[PositioningComponent.self] = positioningComponent
        }
    }
}
```

### 3. Explicitly Trigger Repositioning Where Needed
- **IntroView/IntroViewModel:** Call `introRoot.checkHeadPosition()` after the environment is set up or before starting an animation sequence.
- **LabView/LabViewModel:** Invoke `checkHeadPosition()` when transitioning into the lab environment to update positioning before interaction.
- **AttackCancerView/AttackCancerViewModel:** Use `checkHeadPosition()` before starting tutorials or game sequences.

### 4. Maintain Existing Safety and Fallbacks
- Query the device anchor.
- Validate head position (with fallbacks if translation is too small or high).
- Reset `needsPositioning` to false upon a successful update.

## Usage Example

```swift
let headTrackingRoot = Entity()
headTrackingRoot.name = "headTrackingRoot"
headTrackingRoot.components.set(PositioningComponent(
    offsetX: 0,
    offsetY: 0,
    offsetZ: -1.0,
    needsPositioning: false,
    shouldAnimate: false,
    animationDuration: 0.0
))

headTrackingRoot.checkHeadPosition(animated: true, duration: 0.5)
```

## Benefits
1. **Explicit Control:** Developers manually trigger head position updates at precise moments.
2. **Improved Consistency:** A uniform pattern ensures repositioning is deliberate.
3. **Resource Efficiency:** Updates occur only when needed, reducing unnecessary computations.

## Implementation Plan
1. **Add the New API:** Implement `checkHeadPosition()` in `Entity`.
2. **Update Entity Initializations:** Ensure immersive scenes set up `PositioningComponent` with `needsPositioning: false`.
3. **Integrate Explicit Calls:** Insert `checkHeadPosition()` in appropriate moments within view models.
4. **Testing:**
   - Verify `checkHeadPosition()` triggers head position updates.
   - Validate fallback behavior in `refreshPosition()` from `IntroViewModel`.
   - Ensure changes do not conflict with animations or state transitions.

By following these instructions, head-based positioning will be more precise and visually smooth, aligning with visionOS 2 best practices.

