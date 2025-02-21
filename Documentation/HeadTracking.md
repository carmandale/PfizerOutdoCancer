# Head Tracking and Positioning System

## Overview
The head tracking and positioning system in the Pfizer Outdo Cancer app manages the positioning of entities relative to the user's head position. This system is critical for maintaining proper viewing angles and comfort in visionOS.

## Core Components

### PositioningComponent
```swift
public struct PositioningComponent: Component, Codable {
    var offsetX: Float
    var offsetY: Float
    var offsetZ: Float
    var needsPositioning: Bool
    var shouldAnimate: Bool
    var animationDuration: TimeInterval
    var isAnimating: Bool
}
```

### PositioningSystem
A RealityKit system that handles entity positioning relative to the device's position. Key features:
- Validates distances (0.3m min to 3.0m max from device)
- Handles animation of position changes
- Manages positioning state

## PositioningSystem Implementation

### Safety Features
```swift
// Distance Validation
let minValidDistance: Float = 0.3  // Minimum 0.3 meters from device
let maxValidDistance: Float = 3.0   // Maximum 3 meters from device

// Position clamping for safety
if distanceFromDevice < minValidDistance || distanceFromDevice > maxValidDistance {
    // Calculate direction vector from device to target
    let direction = normalize(targetPosition - devicePosition)
    // Clamp distance to valid range
    let clampedDistance = simd_clamp(distanceFromDevice, minValidDistance, maxValidDistance)
    // Calculate new position at clamped distance
    finalPosition = devicePosition + (direction * clampedDistance)
}
```

### State Management
The system tracks multiple states to ensure proper positioning:
- `needsPositioning`: Triggers position updates
- `isAnimating`: Prevents concurrent animations
- `shouldAnimate`: Controls animation behavior
- `animationDuration`: Specifies animation timing

### Device Anchor Validation
```swift
guard case .running = appModel.trackingManager.worldTrackingProvider.state,
      let deviceAnchor = appModel.trackingManager.worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else {
    return
}
```

### Animation Handling
The system provides two positioning methods:
1. **Immediate**: Direct position setting
```swift
entity.setPosition(finalPosition, relativeTo: nil)
```

2. **Animated**: Smooth transitions
```swift
await entity.animateAbsolutePosition(
    to: finalPosition,
    duration: component.animationDuration,
    timing: .easeInOut,
    waitForCompletion: false
)
```

### Logging and Debugging
The system includes comprehensive logging:
```swift
Logger.debug("""

📍 Positioning entity '\(entity.name)'
├─ From: \(entity.position)
├─ To: \(finalPosition)
├─ Offsets: [\(component.offsetX), \(component.offsetY), \(component.offsetZ)]
├─ Distance: \(distanceFromDevice)m
└─ Method: \(component.shouldAnimate ? "Animated (\(component.animationDuration)s)" : "Immediate")
""")
```

## Start Button Flow

1. **Initial Trigger**
```swift
// In StartButton.swift
NavigationButton(
    title: "Start",
    action: {
        Task {
            appModel.introState.shouldUpdateHeadPosition = true
        }
    }
)
```

2. **Position Update Handler**
```swift
// In IntroView.swift
.onChange(of: appModel.introState.shouldUpdateHeadPosition) { _, shouldUpdate in
    if shouldUpdate && appModel.introState.isReadyForHeadTracking && !appModel.introState.isPositioningInProgress {
        if let root = appModel.introState.introRootEntity {
            Task { @MainActor in
                appModel.introState.isPositioningInProgress = true
                
                if var positioningComponent = root.components[PositioningComponent.self] {
                    positioningComponent.needsPositioning = true
                    positioningComponent.shouldAnimate = true
                    positioningComponent.animationDuration = 0.5
                    root.components[PositioningComponent.self] = positioningComponent
                    
                    try? await Task.sleep(for: .seconds(0.6))
                    
                    appModel.introState.shouldUpdateHeadPosition = false
                    appModel.introState.isPositioningComplete = true
                    appModel.introState.isPositioningInProgress = false
                }
            }
        }
    }
}
```

## State Management

### Required States
```swift
isReadyForHeadTracking      // Must be true to begin
isPositioningInProgress     // Tracks active positioning
isPositioningComplete       // Signals completion
shouldUpdateHeadPosition    // Trigger flag
```

### Default Positions
The system defines standard positions for different phases of the experience:

```swift
// In AppModel.swift
enum PositioningDefaults {
    case intro
    case building
    case playing
    
    var position: SIMD3<Float> {
        switch self {
        case .intro:    return SIMD3<Float>(0.0, -1.5, -1.0)  // Below eye level for intro
        case .building: return SIMD3<Float>(0.0, 1.2, -1.0)   // Slightly above eye level for building
        case .playing:  return SIMD3<Float>(0.0, 1.5, -1.0)   // Higher position for gameplay
        }
    }
}
```

These positions are used in their respective views:
- `IntroView`: Uses `.intro` position for initial setup
- `ADCBuilder`: Uses `.building` position for construction phase
- `AttackCancer`: Uses `.playing` position for gameplay

## Validation and Safety

The PositioningSystem enforces:
- Minimum distance: 0.3 meters from device
- Maximum distance: 3.0 meters from device
- Automatic position clamping when outside valid range

## Integration Points

### LoadingView
- Houses the StartButton
- Transitions to immersive experience after positioning

### IntroView
- Handles positioning execution
- Manages state transitions
- Controls animation sequence

### IntroViewModel
- Manages root entity setup
- Tracks positioning states
- Handles cleanup

### IntroView Implementation
```swift
// In IntroViewModel.swift
func setupRoot() -> Entity {
    let root = Entity()
    root.name = "IntroRoot"
    root.position = AppModel.PositioningDefaults.intro.position
    
    root.components.set(PositioningComponent(
        offsetX: 0,
        offsetY: -1.5,  // Maintain intro's specific offset
        offsetZ: -1.0,
        needsPositioning: false,
        shouldAnimate: false,
        animationDuration: 0.0
    ))
    
    introRootEntity = root
    isRootSetupComplete = true
    isHeadTrackingRootReady = true
    return root
}
```

### AttackCancer Implementation
```swift
// In AttackCancerViewModel+SceneSetup.swift
func setupRoot() -> Entity {
    let root = Entity()
    root.name = "AttackCancerRoot"
    
    let headTrackingRoot = Entity()
    headTrackingRoot.position = AppModel.PositioningDefaults.playing.position
    headTrackingRoot.name = "headTrackingRoot"
    headTrackingRoot.components.set(PositioningComponent(
        offsetX: 0,
        offsetY: 0,
        offsetZ: -1.0,
        needsPositioning: false,
        shouldAnimate: false,
        animationDuration: 0.0
    ))
    root.addChild(headTrackingRoot)
    
    rootEntity = root
    isRootSetupComplete = true
    isHeadTrackingRootReady = true
    return root
}
```

### ADCOptimizedImmersive Implementation
```swift
// In ADCOptimizedImmersive.swift
.onChange(of: dataModel.shouldUpdateHeadPosition) { _, shouldUpdate in
    if shouldUpdate && dataModel.isReadyForInteraction {
        if let root = mainEntity {
            Logger.info("""
            
            🎯 Head Position Update Requested
            ├─ Current World Position: \(root.position(relativeTo: nil))
            ├─ Root Setup: \(dataModel.isRootSetupComplete ? "✅" : "❌")
            ├─ Environment: \(dataModel.isEnvironmentSetupComplete ? "✅" : "❌")
            └─ HeadTracking: \(dataModel.isHeadTrackingRootReady ? "✅" : "❌")
            """)
            
            Task {
                root.checkHeadPosition(animated: true, duration: 0.5)
                dataModel.shouldUpdateHeadPosition = false
                dataModel.isPositioningComplete = true
            }
        }
    }
}
```

## Best Practices

### State Management
- Always check all required conditions before positioning
- Use proper state flags to prevent multiple positioning attempts
- Reset states after completion

### Animation
- Use appropriate duration (0.5s standard)
- Include buffer time for completion (0.6s total)
- Ensure smooth transitions

### Error Handling
- Validate entity existence
- Check component attachment
- Monitor state transitions

## Debugging

### Logging
The system includes detailed logging:
```swift
Logger.info("=== Start Button Pressed ===")
Logger.info("Current Phase: \(appModel.currentPhase)")
Logger.info("isReadyForInteraction: \(appModel.introState.isReadyForHeadTracking)")
Logger.info("Setting shouldUpdateHeadPosition = true")
```

### State Inspection
Monitor these states for troubleshooting:
- `isReadyForHeadTracking`
- `isPositioningInProgress`
- `isPositioningComplete`
- `shouldUpdateHeadPosition`

## Common Issues

### Positioning Not Triggering
Check:
- Loading completion status
- Entity initialization
- Component attachment
- State flag values

### Incorrect Positioning
Verify:
- Offset values
- Animation duration
- State transitions
- Entity hierarchy

### Multiple Positioning Attempts
Ensure:
- Proper state management
- Single trigger point
- Complete state reset
- Proper condition checking

## Future Considerations

### Potential Enhancements
- Dynamic offset calculation
- Advanced animation curves
- Additional positioning options
- Extended state management

### Maintenance
- Monitor visionOS updates
- Update positioning logic as needed
- Maintain state management
- Keep documentation current

## Reset Process

### State Reset Sequence
```swift
// 1. Animation Cancellation
animationTask?.cancel()
animationTask = nil

// 2. Entity Cleanup
if let root = introRootEntity {
    if var positioningComponent = root.components[PositioningComponent.self] {
        positioningComponent.needsPositioning = true
        root.components[PositioningComponent.self] = positioningComponent
    }
    root.removeFromParent()
}
introRootEntity = nil

// 3. State Flags Reset
isRootSetupComplete = false
isEnvironmentSetupComplete = false
isHeadTrackingRootReady = false
shouldUpdateHeadPosition = false
isPositioningComplete = false
isPositioningInProgress = false

// 4. Cross-Component Reset
appModel.readyToStartLab = false
```

### Reset Validation
The system includes comprehensive logging to verify reset completion:
```swift
Logger.info("""

🔄 === INTRO VIEW CLEANUP STATE ===
├─ Root Setup: \(isRootSetupComplete)
├─ Environment Setup: \(isEnvironmentSetupComplete)
├─ Head Tracking Ready: \(isHeadTrackingRootReady)
├─ Should Update Position: \(shouldUpdateHeadPosition)
├─ Positioning Complete: \(isPositioningComplete)
├─ Positioning In Progress: \(isPositioningInProgress)
├─ Has Root Entity: \(introRootEntity != nil)
└─ Has Positioning Component: \(introRootEntity?.components[PositioningComponent.self] != nil)
""")
```

### Reset Triggers
Reset occurs in the following scenarios:
1. During IntroViewModel cleanup
2. When setting up a new root
3. When transitioning between app phases
4. When immersive space is dismissed by system 