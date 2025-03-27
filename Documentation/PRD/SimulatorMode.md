# Simulator Mode Support PRD

## Overview
This document outlines the requirements and implementation for simulator fallback mode in the Honda Target Vehicle AVP application. Simulator mode enables the app to run in the iOS/visionOS simulator without reliance on actual ARKit world tracking functionality.

## Motivation
VisionOS apps relying on ARKit tracking features cannot properly function in the simulator because the simulator cannot provide real-world spatial tracking data. To enable development and testing in the simulator, we need a way to simulate head position values that would normally come from ARKit.

## Requirements

### Core Requirements
1. Detect when the app is running in the simulator environment
2. Provide fallback position values when ARKit tracking isn't available
3. Skip actual tracking initialization in the simulator
4. Maintain the same code paths where possible for consistency

### Implementation Details

#### 1. Added to hondaApp.swift
```swift
// Set simulator fallback values if needed
#if targetEnvironment(simulator)
Logger.info("🧪 Running in simulator - using fallback position values")
PositioningSystem.setSimulatorMode(true)
PositioningSystem.setFallbackPosition(SIMD3<Float>(-0.0002527883, 0.9118354, 0.20180774))
#endif
```

#### 2. Added to PositioningSystem.swift
```swift
// Simulator fallback values
private static var isSimulatorMode: Bool = false
private static var fallbackPosition: SIMD3<Float> = SIMD3<Float>(-0.0002527883, 0.9118354, 0.20180774)

// Set simulator mode
static func setSimulatorMode(_ enabled: Bool) {
    isSimulatorMode = enabled
    Logger.info("\n🧪 PositioningSystem simulator mode \(enabled ? "enabled" : "disabled")")
}

// Set fallback position for simulator
static func setFallbackPosition(_ position: SIMD3<Float>) {
    fallbackPosition = position
    Logger.info("\n🧪 PositioningSystem fallback position set to \(position)")
}
```

The update method was modified to use these values:
```swift
// Get current device position - either from tracking or fallback
let devicePosition: SIMD3<Float>

if Self.isSimulatorMode {
    // Use fallback position for simulator
    devicePosition = Self.fallbackPosition
    // Log occasionally without using frame count
    Logger.debug("\n🧪 Using simulator fallback position: \(devicePosition)")
} else {
    // Normal tracking code path...
}
```

#### 3. Added to TrackingSessionManager.swift
```swift
// Check for simulator environment
#if targetEnvironment(simulator)
Logger.info("""
=== TRACKING SESSION IN SIMULATOR ===
├─ Detected simulator environment
├─ Using fallback positioning instead of active tracking
""")
isTracking = true
return
#endif
```

## Benefits
1. **Development Efficiency**: Allows testing in the simulator without requiring a physical device
2. **Integration Testing**: Enables testing of UI and app flow without ARKit functionality
3. **Debugging**: Simplifies debugging by providing consistent positioning values

## Limitations
1. The simulator cannot test actual spatial tracking accuracy
2. Interaction with real-world objects isn't possible
3. Hand tracking and other ARKit features aren't simulated

## Future Enhancements
1. Ability to change simulated position via debug controls
2. Simulation of movement patterns
3. Expanded simulation for other tracking features 