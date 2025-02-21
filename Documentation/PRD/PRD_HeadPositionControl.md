# Refined Head Position Control PRD

## Overview
The goal is to enhance control over head-based positioning within immersive scenes by enabling explicit on-demand updates. Currently, the `PositioningSystem` automatically updates an entity's position when the `needsPositioning` flag in its `PositioningComponent` is true. After an update, the flag resets to false. By introducing explicit control, developers can choose when any immersive view (e.g., Intro, Lab, AttackCancer) should re-evaluate and update its positioning relative to the user's head position.

## System Setup
### Component Registration
```swift
// In PfizerOutdoCancerApp.swift
PositioningSystem.registerSystem()
PositioningComponent.registerComponent()
```

### AppModel Reference Setup
```swift
// Required setup for PositioningSystem
static func setAppModel(_ appModel: AppModel) {
    Logger.debug("🔄 PositioningSystem.setAppModel called")
    sharedAppModel = appModel
}
```

## Current Behavior
- **Automatic Update:**  
  - Entities with a `PositioningComponent` having `needsPositioning` set to true are repositioned according to the user's current head position.
  - Once updated, the flag resets to false, preventing continuous updates.
  
- **Usage in the Codebase:**  
  - Views like *IntroView.swift*, *LabView.swift*, and *AttackCancerView.swift* set up their root entities with a `PositioningComponent` and use state management to trigger repositioning.
  - Position updates are triggered through state changes (`shouldUpdateHeadPosition`) and handled by view modifiers.
  - Each view implements proper state tracking for positioning progress and completion.

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

### 3. AttackCancer State Management
```swift
// In AttackCancerViewModel
// State tracking for positioning readiness
var isRootSetupComplete: Bool = false
var isEnvironmentSetupComplete: Bool = false
var isHeadTrackingRootReady: Bool = false

// Composite state for interaction readiness
var isReadyForInteraction: Bool {
    isRootSetupComplete && 
    isEnvironmentSetupComplete && 
    isHeadTrackingRootReady
}

// Setup sequence with state tracking
func setupRoot() -> Entity {
    // Reset state tracking first
    isRootSetupComplete = false
    isEnvironmentSetupComplete = false
    isHeadTrackingRootReady = false
    
    let root = Entity()
    let headTrackingRoot = Entity()
    headTrackingRoot.components.set(PositioningComponent(
        offsetX: 0,
        offsetY: 0,
        offsetZ: -1.0,
        needsPositioning: false
    ))
    
    // Update state after successful setup
    isRootSetupComplete = true
    isHeadTrackingRootReady = true
    return root
}
```

### State Management Best Practices
1. **State Initialization:**
   - Reset all state flags at the start of setup
   - Track individual component states separately
   - Use composite state for complex conditions

2. **State Dependencies:**
   - Environment must be ready before positioning
   - Root setup must complete before tracking
   - All states must be true before interaction

3. **Reset Scheme:**
   - Reset states when transitioning between phases
   - Clear states before new setup sequences
   - Maintain state consistency during cleanup

4. **Position Update Triggers:**
   - Only trigger updates when all states are ready
   - Check `isReadyForInteraction` before updates
   - Reset `shouldUpdateHeadPosition` after updates

5. **Logging and Validation:**
   - Log state changes for debugging
   - Include state information in position logs
   - Validate state before critical operations

Example state-aware position update:
```swift
.onChange(of: shouldUpdateHeadPosition) { _, shouldUpdate in
    if shouldUpdate && isReadyForInteraction {
        if let headTrackingRoot = root.findEntity(named: "headTrackingRoot") {
            Logger.info("""
            
            🎯 Head Position Update Requested
            ├─ Phase: \(currentPhase)
            ├─ Current World Position: \(headTrackingRoot.position(relativeTo: nil))
            ├─ Root Setup: \(isRootSetupComplete ? "✅" : "❌")
            ├─ Environment: \(isEnvironmentSetupComplete ? "✅" : "❌")
            └─ HeadTracking: \(isHeadTrackingRootReady ? "✅" : "❌")
            """)
            
            headTrackingRoot.checkHeadPosition(animated: true)
            shouldUpdateHeadPosition = false
        }
    }
}
```

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

## Implementation Examples

### 1. IntroView Implementation
```swift
// In IntroView.swift
RealityView { content, attachments in
    // Create fresh root entity
    let root = appModel.introState.setupIntroRoot()
    root.components.set(PositioningComponent(
        offsetX: 0,
        offsetY: -1.5,  // Adjust Y offset for intro view height
        offsetZ: -1.0,
        needsPositioning: false,  // Start false, enable when ready
        shouldAnimate: true,
        animationDuration: 0.5
    ))
    content.add(root)
}
```

### 2. ADCOptimizedImmersive Implementation
```swift
// In ADCOptimizedImmersive.swift
RealityView { content, attachments in
    let masterEntity = Entity()
    masterEntity.components.set(PositioningComponent(
        offsetX: 0,
        offsetY: 0,
        offsetZ: -1.0,
        needsPositioning: false,  // Will be triggered by state changes
        shouldAnimate: true,
        animationDuration: 0.5
    ))
    masterEntity.name = "MainEntity"
    contentRef.add(masterEntity)
}
```

### Key Implementation Points
1. **Component Setup:**
   - Set `needsPositioning = false` initially
   - Configure appropriate offsets for your view
   - Enable animation with suitable duration

2. **Position Updates:**
   - Trigger updates by setting `needsPositioning = true`
   - System handles animation and position validation
   - Logs provide feedback on start and completion

3. **Animation Control:**
   - Use `isAnimating` flag to prevent duplicate logs
   - System automatically manages animation state
   - Position updates complete when animation finishes

4. **Best Practices:**
   - Keep offsets view-specific (e.g., lower Y for IntroView)
   - Use animation for smooth transitions
   - Monitor logs for positioning feedback
   - Let system handle device anchor validation

5. **Validation:**
   - System enforces min/max distances
   - Automatically clamps positions to valid range
   - Provides debug logging for invalid positions

By following these implementation steps, you ensure consistent head-based positioning across different views while maintaining smooth animations and proper distance constraints.

