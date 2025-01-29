# ADC Firing System Update Plan

## Current System Overview
The ADC firing system currently requires:
1. A valid cancer cell target
2. Line of sight to the target
3. Available attachment point on the target
4. Valid hand position for spawning

## Proposed Changes

### 1. ADCComponent Updates
```swift
public struct ADCComponent: Component {
    public enum State {
        case idle
        case moving
        case attached
        case seeking  // New state for untargeted ADCs
    }
    
    // Existing properties
    var state: State = .idle
    var startWorldPosition: SIMD3<Float>?
    var movementProgress: Float = 0
    var targetEntityID: EntityID?
    var targetCellID: Int?
    var proteinSpinSpeed: Float
    var speedFactor: Float?
    var arcHeightFactor: Float?
    
    // New properties
    var initialDirection: SIMD3<Float>?  // Direction when fired
    var seekingStartTime: TimeInterval?  // When seeking began
}
```

### 2. Spawning System Updates (`AttackCancerViewModel+HandInteraction.swift`)
1. Update `handleTap` to support untargeted firing:
   ```swift
   func handleTap(on entity: Entity, location: SIMD3<Float>, in scene: RealityKit.Scene?) async {
       // Get hand position (existing logic)
       let handPosition = determineHandPosition()
       
       // Try to find target cell (existing logic)
       if let cellID = findTargetCell(entity) {
           await spawnTargetedADC(from: handPosition, forCellID: cellID)
       } else {
           // New untargeted path
           let direction = calculateFiringDirection(from: handPosition)
           await spawnUntargetedADC(from: handPosition, direction: direction)
       }
   }
   ```

### 3. Movement System Updates (`ADCMovementSystem.swift`)

#### Existing Parameters to Leverage
```swift
static let numSteps: Double = 120
static let baseStepDuration: TimeInterval = 0.016
static let speedRange: ClosedRange<Float> = 1.2...3.0
static let rotationSmoothingFactor: Float = 12.0
static let maxBankAngle: Float = .pi / 8
```

#### New Parameters
```swift
static let seekingDuration: TimeInterval = 3.0
static let seekingSpeed: Float = 2.0
static let seekingTurnRate: Float = 1.0
static let maxSeekingRange: Float = 5.0
static let seekingUpdateInterval: TimeInterval = 0.5  // How often to check for targets
```

#### Movement Implementation
1. Leverage existing Bezier curve system:
   ```swift
   func updateSeekingADC(_ entity: Entity, _ adc: inout ADCComponent) {
       // Initial straight movement using existing path calculation
       if let direction = adc.initialDirection {
           let currentPos = entity.position(relativeTo: nil)
           let targetPos = currentPos + direction * seekingSpeed
           
           // Use existing Bezier curve with reduced arc
           let midPoint = mix(currentPos, targetPos, t: 0.5)
           let controlPoint = midPoint + SIMD3<Float>(0, 0.2, 0)  // Minimal arc
           
           // Apply existing smooth movement
           updatePosition(entity, start: currentPos, control: controlPoint, target: targetPos)
       }
       
       // Target detection using existing retargeting system
       if shouldCheckForTargets(adc) {
           if let (newTarget, newCellID) = findNewTarget(for: entity,
                                                        currentPosition: entity.position,
                                                        in: scene) {
               transitionToTargeted(entity, &adc, newTarget, newCellID)
           }
       }
   }
   ```

### 4. Integration with Existing Systems

#### Collision System
- Leverage existing collision handling:
  ```swift
  func handleCollisionBegan(_ event: CollisionEvents.Began) {
      // Existing collision detection
      if let adcComponent = entity.components[ADCComponent.self] {
          switch adcComponent.state {
          case .seeking:
              handleSeekingCollision(entity, &adcComponent, event)
          default:
              handleNormalCollision(entity, &adcComponent, event)
          }
      }
  }
  ```

#### Retargeting System
- Use existing `findNewTarget` function with modifications:
  ```swift
  static func findNewTarget(for adcEntity: Entity,
                          currentPosition: SIMD3<Float>,
                          in scene: Scene,
                          maxRange: Float? = nil) -> (Entity, Int)?
  ```

## Implementation Phases

### Phase 1: Core Updates (2-3 days)
1. Add seeking state to ADCComponent
2. Update handleTap for untargeted mode
3. Implement initial straight-line movement

### Phase 2: Movement System (3-4 days)
1. Integrate seeking behavior with existing movement
2. Implement periodic target checking
3. Add smooth transitions between states

### Phase 3: Testing & Refinement (2-3 days)
1. Test seeking behavior
2. Verify collision handling
3. Performance optimization
4. Edge case handling

## Risk Assessment

### Technical Risks
1. Performance impact of target checking
   - Mitigation: Use existing spatial query system
   - Implement checking interval
   
2. State management complexity
   - Mitigation: Leverage existing state system
   - Clear transition conditions

3. Physics interaction edge cases
   - Mitigation: Use existing collision system
   - Add specific seeking collision responses

## Next Steps
1. Review updated plan
2. Begin Phase 1 implementation
3. Create test scenarios
4. Schedule performance testing 