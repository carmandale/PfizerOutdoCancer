# ADC Retargeting Motion Smoothing Plan

## Current Issues Analysis
![Retargeting Transition Diagram](diagram-url) *Conceptual diagram showing harsh transition points*

**Identified Problem Areas:**
1. Path discontinuity between original and new trajectory
2. Instant reset of movement parameters
3. Abrupt orientation changes
4. Velocity phase mismatch during transitions

## Core Solutions Strategy

### 1. Path Continuity System
**Approach:** Composite Bézier Curves
```swift
struct PathTransition {
    let previousControl: SIMD3<Float>
    let newControl: SIMD3<Float>
    let blendDuration: TimeInterval
}
```

**Implementation:**
- Create hybrid path using last segment of old curve + first segment of new curve
- Maintain C1 continuity at transition point
- Use cubic Bézier during transition period

### 2. Motion Context Preservation
**Key Parameters to Preserve:**
- Velocity direction at retarget moment
- Current movement phase (accel/cruise/decel)
- Vertical momentum

**New Component Properties:**
```swift
// ADCComponent additions
var transitionVelocity: SIMD3<Float>?
var pathTransitionProgress: Float = 0
var isInTransition: Bool = false
var previousMovementPhase: MovementPhase = .cruising
```

### 3. Orientation Smoothing
**Rotation Handling:**
- Spherical interpolation (slerp) between old/new orientations
- Progressive banking adjustment
- Maintain angular velocity continuity

```swift
let blendFactor = min(1.0, transitionProgress * 5.0)
let newOrientation = simd_slerp(
    currentOrientation, 
    targetOrientation, 
    blendFactor
)
```

### 4. Parameter Transition System
**Gradual Blending:**
| Parameter        | Blend Time | Curve Type      |
|-------------------|------------|-----------------|
| Speed Factor      | 0.4s       | Ease-In-Out     |
| Arc Height        | 0.6s       | Ease-Out        |
| Banking Angle     | 0.3s       | Linear          |

## Enhanced Implementation Strategy

### 1. Advanced Path Continuity
**Composite Curve Enhancements:**
- **C0/C1 Continuity Enforcement:**
  - Match position (C0) and derivative (C1) at transition points
  - Construct bridging curve using current velocity vector
  ```swift
  let bridgeCurve = CubicBezier(
      p0: currentPosition,
      p1: currentPosition + velocity * 0.2,
      p2: newPathStart - newVelocity * 0.2,
      p3: newPathStart
  )
  ```

**Cross-Fade Transition (Advanced Option):**
- Simultaneously evaluate old and new paths during transition
- Blend positions over 0.15-0.3s window
- Weighted average: `position = oldPos*(1-alpha) + newPos*alpha`

### 2. Phase-Aware Motion Preservation
**Enhanced Context Tracking:**
```swift
struct MovementPhaseContext {
    var currentPhase: MovementPhase
    var phaseProgress: Float
    var verticalMomentum: Float
    var horizontalVelocity: SIMD3<Float>
}
```

**Implementation:**
- Maintain velocity vector continuity between paths
- Preserve vertical momentum through arc transitions
- Phase-consistent acceleration profiles

### 3. Refined Orientation Handling
**Quaternion Blending System:**
- Configurable blend window (0.2-0.4s)
- Bank angle sign consistency check
```swift
let bankSign = preserveBankSign ? 
    sign(currentBankAngle) : 
    sign(targetBankAngle)

let blendedBank = mix(
    currentBankAngle, 
    targetBankAngle * bankSign, 
    deltaTime * bankingSmoothingFactor
)
```

**Progressive Slerp Implementation:**
```swift
let blendDuration: TimeInterval = 0.3
let blendProgress = min(1.0, transitionTime / blendDuration)
let smoothOrientation = simd_slerp(
    previousOrientation, 
    targetOrientation, 
    smoothstep(0, 1, blendProgress)
)
```

### 4. Parameter Transition System
**Gradual Factor Blending:**
```swift
struct TransitionParameters {
    var targetSpeedFactor: Float
    var targetArcHeight: Float
    var transitionStartTime: TimeInterval
    let transitionDuration: TimeInterval = 0.5
}

func updateFactors() {
    let t = clamp(transitionProgress, 0, 1)
    let smoothT = smoothstep(0, 1, t)
    currentSpeed = mix(oldSpeed, targetSpeed, smoothT)
    currentArcHeight = mix(oldArc, targetArc, smoothT)
}
```

**Delta-Time Aware Mixing:**
```swift
let blendFactor = 1 - exp(-deltaTime * blendRate)
adcComponent.speedFactor = mix(
    adcComponent.speedFactor,
    adcComponent.targetSpeedFactor,
    blendFactor
)
```

## Enhanced Implementation Phases

### Phase 1: Core Systems (Updated)
1. **Velocity Preservation System**
   - Store instant velocity vector at retarget moment
   - Convert to initial tangent for new path
2. **Phase Continuity**
   - Maintain acceleration/cruise/decel state
   - Carry forward phase progress percentage

### Phase 2: Advanced Transition Options
1. **Cross-Fade Path Blending**
   - Parallel path evaluation
   - Position/rotation averaging
2. **Bank Angle Consistency**
   - Sign preservation system
   - Smooth angle transitions

## Updated Testing Plan

**New Edge Cases:**
1. High-speed retargets (>5m/s)
2. 180° direction changes
3. Minimum-distance retargets (<0.5m)
4. Vertical arc inversions

**Enhanced Metrics:**
1. Velocity vector continuity (Δ < 15%)
2. Orientation change rate < 90°/s
3. Parameter transition smoothness (dF/dt < 2.0/s)

## Implementation Additions

**New Component Properties:**
```swift
// ADCComponent extensions
var transitionContext: TransitionContext?
var targetBankAngle: Float = 0
var velocityAtRetarget: SIMD3<Float>?
var crossFadeProgress: Float = 0
```

**Enhanced Debug Tools:**
- Velocity vector visualization
- Transition progress overlays
- Phase state indicators
- Blend factor telemetry

## Revised Timeline

| Phase         | Duration | Key Additions                     |
|---------------|----------|------------------------------------|
| Core Systems  | 6 Days   | Velocity preservation, Phase carry|
| Advanced      | 4 Days   | Cross-fade, Bank consistency      |
| Final Polish  | 3 Days   | Parameter tuning, Edge cases      |

**Final Target:** VisionOS 2.1 Update Candidate

## Required Support Systems

1. **Path Continuity Validation**
   - Ensure derivative matching at transition points
   - Automatic fallback to simple path if continuity fails

2. **Transition State Management**
   ```swift
   enum TransitionState {
       case none
       case preparing(transitionStartTime: TimeInterval)
       case active(PathTransition)
       case completing
   }
   ```

3. **Debug Visualization**
   - Draw both old/new paths during transition
   - Show velocity vectors and control points

## Testing Plan

**Validation Metrics:**
1. Angular acceleration < 180°/s²
2. Path curvature continuity (C1)
3. Speed variance < 15% during transitions
4. Frame time consistency (±2ms)

**Test Cases:**
1. Mid-curve retargeting
2. High-speed collision retargeting
3. Vertical arc transitions
4. Rapid sequential retargeting

## Code Impact Analysis

**Modified Files:**
1. `ADCMovementSystem.swift`
   - Path calculation system
   - State transition handling
2. `ADCMovementSystem+Retargeting.swift`
   - Retargeting logic updates
3. `ADCComponent.swift`
   - New state properties

**New Files:**
1. `ADCMovementSystem+PathMath.swift`
2. `TransitionStateComponent.swift`

## Risk Mitigation

1. **Performance Impact**
   - Limit transition calculations to 2 active transitions per frame
   - Use precomputed Bézier factors

2. **Edge Cases**
   - Minimum transition distance check
   - Timeout for stuck transitions
   - Fallback to legacy system

## Timeline & Resources

| Phase       | Duration | Owner          |
|-------------|----------|----------------|
| Core Systems| 5 Days   | Movement Team  |
| Testing     | 3 Days   | QA Team        |
| Polish      | 2 Days   | Graphics Team  |

**Final Implementation Target:** VisionOS 2.1 Update 