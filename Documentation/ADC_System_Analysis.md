# ADC (Antibody-Drug Conjugate) System Analysis

This document provides a detailed analysis of the ADC system implementation in the VisionOS application, covering its components, behaviors, and key processes.

## Table of Contents
1. [ADC Structure](#adc-structure)
2. [Movement System](#movement-system)
3. [Antigen Attachment Process](#antigen-attachment-process)
4. [Physics and Collision System](#physics-and-collision-system)
5. [Cancer Cell Interaction](#cancer-cell-interaction)

## ADC Structure

The ADC system models Antibody-Drug Conjugates with three main components:

1. **Antibody**
   - Represented by `selectedADCAntibody` in `ADCDataModel`
   - Different types identified by color indices
   - Primary targeting component that determines antigen specificity

2. **Linker**
   - Tracked by `selectedLinkerType`
   - Connects antibody to payload
   - Visual representation includes 4 linker points

3. **Payload**
   - Managed by `selectedPayloadType`
   - Represents the drug component
   - Includes inner and outer sphere visualizations with emissive properties

## Movement System

The `ADCMovementSystem` manages ADC movement with sophisticated parameters:

```swift
static let numSteps: Double = 120     // Smooth motion steps
static let baseArcHeight: Float = 1.2 // Arc height for movement
static let speedRange: ClosedRange<Float> = 1.2...3.0
static let rotationSmoothingFactor: Float = 12.0
static let maxBankAngle: Float = .pi / 8
```

Key movement features:
- Bezier curve-based paths for natural motion
- Speed variation with acceleration/deceleration phases
- Banking and rotation for realistic 3D movement
- Dynamic retargeting capabilities

## Antigen Attachment Process

The system implements two distinct methods for ADC targeting and attachment:

1. **Direct Targeting Mode**
   ```swift
   func spawnADC(from position: SIMD3<Float>, targetPoint: Entity, forCellID cellID: Int)
   ```
   - Used when player specifically targets a cancer cell
   - ADC is spawned with predetermined target point and cell ID
   - Moves directly to assigned attachment point
   - No selection process needed - target is explicitly defined

2. **Autonomous Seeking Mode**
   ```swift
   func spawnUntargetedADC(from position: SIMD3<Float>)
   ```
   - ADC initially moves to random position in player's view:
     ```swift
     let randomX = Float.random(in: -1.0...1.0)
     let randomY = Float.random(in: 0.5...1.5)
     let randomZ = Float.random(in: -3.5...(-2.5))
     ```
   - Once in range, uses closest-point selection for targeting
   - Selection criteria for autonomous targeting:
     - Point must not be occupied (`!attachComponent.isOccupied`)
     - Parent cancer cell must exist and not be destroyed
     - Cell must not have reached required hit count
     - Point must be at least 0.3 units away from ADC

3. **Attachment Point Management**
   - Points are initialized during cancer cell spawning:
   ```swift
   private func setupAttachmentPoints(for cell: Entity, complexCell: Entity, cellID: Int) {
       // Find and configure attachment points
       let attachPointQuery = EntityQuery(where: .has(AttachmentPoint.self))
       // Assign cell ID to each point
   }
   ```
   - Each point tracks:
     - Occupation status (`isOccupied`)
     - Parent cell ID (`cellID`)
   - States update in real-time as ADCs attach/detach

4. **Physical Attachment Process**
   ```swift
   func handleADCToCellCollision(adc: Entity, cell: Entity, collision: CollisionEvents.Began)
   ```
   - Uses RealityKit's collision system for detection
   - Applies scaled physics forces on attachment:
     ```swift
     let scaledImpulse = collision.impulse * parameters.impactScale * 0.1
     motion.linearVelocity += collision.impulseDirection * scaledImpulse
     ```

This dual targeting system provides both guided gameplay mechanics (direct targeting) and emergent behavior (autonomous seeking), creating an engaging and educational simulation of ADC-cancer cell interactions.

## Physics and Collision System

The collision and physics system provides realistic interactions:

1. **Collision Detection**
   ```swift
   let collision = CollisionComponent(
       shapes: [shape],
       filter: .init(group: .adc, mask: .cancerCell)
   )
   ```

2. **Impact Physics**
   - Scaled impulse calculations
   - Both linear and angular velocity applications
   - Customizable impact parameters per cell type

3. **Movement Physics**
   - Smooth acceleration/deceleration
   - Arc-based trajectories
   - Natural rotation and banking

## Cancer Cell Interaction

Cancer cells implement several key features for ADC interaction:

1. **Cell Parameters**
   - Unique cell ID tracking
   - Hit count management
   - Required hits for destruction (4-8 range)
   - Scale-based damage visualization

2. **Physics Response**
   ```swift
   let scaledImpulse = collision.impulse * parameters.impactScale * 0.1
   motion.linearVelocity += collision.impulseDirection * scaledImpulse
   motion.angularVelocity += normalize(randomRotation) * (scaledImpulse * 2.0)
   ```

3. **Visual Feedback**
   - Progressive scaling based on damage
   - Particle effects on impact
   - Destruction animations

This implementation creates an engaging and educational visualization of how ADCs function in cancer treatment, balancing scientific accuracy with interactive gameplay mechanics.
