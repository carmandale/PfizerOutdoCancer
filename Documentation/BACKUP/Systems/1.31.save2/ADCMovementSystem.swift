// ADCMovementSystem.swift

import RealityKit
import Foundation
import RealityKitContent

/// A system that handles the curved path movement of ADC entities
@MainActor
public class ADCMovementSystem: System {
    /// Query to find entities that have an ADC component in moving state
    static let query = EntityQuery(where: .has(ADCComponent.self))
    
    // Movement parameters
    static let numSteps: Double = 120  // Increased for even smoother motion
    static let baseArcHeight: Float = 1.2
    static let arcHeightRange: ClosedRange<Float> = 0.6...1.2  // Slightly increased range
    static let baseStepDuration: TimeInterval = 0.016  // ~60fps for smoother updates
    static let speedRange: ClosedRange<Float> = 1.2...3.0  // Adjusted for more consistent speed
    static let totalDuration: TimeInterval = numSteps * baseStepDuration
    static let minDistance: Float = 0.5
    static let maxDistance: Float = 3.0
    
    // Rotation parameters
    static let rotationSmoothingFactor: Float = 12.0  // Increased for smoother rotation
    static let maxBankAngle: Float = .pi / 8  // Reduced maximum banking angle
    static let bankingSmoothingFactor: Float = 6.0  // New parameter for banking smoothing
    
    // Acceleration parameters
    static let accelerationPhase: Float = 0.2  // First 20% of movement
    static let decelerationPhase: Float = 0.2  // Last 20% of movement
    static let minSpeedMultiplier: Float = 0.4  // Minimum speed during accel/decel
    
    /// Initialize the system with the RealityKit scene
    required public init(scene: Scene) {}
    
    /// Update the entities to apply movement
    public func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var adcComponent = entity.components[ADCComponent.self],
                  adcComponent.state == .moving,
                  let start = adcComponent.startWorldPosition,
                  let targetID = adcComponent.targetEntityID else { continue }
            
            // Find target entity using ID
            let query = EntityQuery(where: .has(AttachmentPoint.self))
            let entities = context.scene.performQuery(query)
            guard let targetEntity = entities.first(where: { $0.id == Entity.ID(targetID) }) else {
                print("⚠️ Target entity not found - aborting ADC movement")
                adcComponent.state = .idle
                entity.components[ADCComponent.self] = adcComponent
                continue
            }
            
            // Validate target before proceeding
            if !Self.validateTarget(targetEntity, adcComponent, in: context.scene) {
                print("⚠️ Target no longer valid - attempting to find new target")
                
                // Try to find new target
                if Self.retargetADC(entity, 
                                  &adcComponent, 
                                  currentPosition: entity.position(relativeTo: nil),
                                  in: context.scene) {
                    // Successfully retargeted - update component and continue
                    entity.components[ADCComponent.self] = adcComponent
                    continue
                } else {
                    // No valid targets found - reset ADC
                    print("⚠️ No valid targets found - resetting ADC")
                    Self.resetADC(entity: entity, component: &adcComponent)
                    continue
                }
            }
            
            // Get current target position
            let target = targetEntity.position(relativeTo: nil)
            
            // Use the randomized factors
            let speedFactor = adcComponent.speedFactor ?? 1.0
            let arcHeightFactor = adcComponent.arcHeightFactor ?? 1.0
            
            // Calculate speed multiplier based on movement phase
            let speedMultiplier: Float
            if adcComponent.movementProgress < Self.accelerationPhase {
                let t = adcComponent.movementProgress / Self.accelerationPhase
                speedMultiplier = Self.mix(Self.minSpeedMultiplier, 1.0, t: Self.smoothstep(0, 1, t))
            } else if adcComponent.movementProgress > (1.0 - Self.decelerationPhase) {
                let t = (adcComponent.movementProgress - (1.0 - Self.decelerationPhase)) / Self.decelerationPhase
                speedMultiplier = Self.mix(1.0, Self.minSpeedMultiplier, t: Self.smoothstep(0, 1, t))
            } else {
                speedMultiplier = 1.0
            }
            
            // Calculate world-space movement
            let currentSpeed = speedFactor * speedMultiplier
            let distanceThisFrame = currentSpeed * Float(context.deltaTime)
            
            // Update progress based on distance traveled
            if adcComponent.totalPathLength > 0 {
                adcComponent.movementProgress += distanceThisFrame / adcComponent.totalPathLength
            }
            
            if adcComponent.movementProgress >= 0.8 { // At 80% of journey
                // Check if current target is headPosition
                if targetEntity.components[PositioningComponent.self] != nil {
                    print("🎯 ADC at 80% to headPosition - attempting to find cancer cell target")
                    // Try to find a cancer cell target
                    if Self.retargetADC(entity, 
                                      &adcComponent, 
                                      currentPosition: entity.position(relativeTo: nil),
                                      in: context.scene) {
                        // Successfully found new cancer cell target
                        entity.components[ADCComponent.self] = adcComponent
                        // Remove the headPosition entity and its debug sphere
                        targetEntity.removeFromParent()
                        print("✨ Removed headPosition entity after successful retarget")
                        continue
                    }
                    print("⚠️ No cancer cell targets found - continuing to headPosition")
                }
            }

            if adcComponent.movementProgress >= 1.0 {
                // Movement complete
//                print("\n=== ADC Impact ===")
                let impactDirection = normalize(target - start)
//                print("💥 Direction: (\(String(format: "%.2f, %.2f, %.2f", impactDirection.x, impactDirection.y, impactDirection.z)))")
                
                if let cancerCell = Self.findParentCancerCell(for: targetEntity, in: context.scene) {
                    print("Found cancer cell: \(cancerCell.name)")
                    // Launch the animation in a Task to handle the async call
                    Task { @MainActor in
                        await cancerCell.hitScaleAnimation(
                            intensity: 0.9, // Less squish (0.95 instead of 0.9)
                            duration: 0.25,  // Faster animation (0.2 instead of 0.3)
                            scaleReduction: 0.12
                        )
                    }
                } else {
                    print("No cancer cell found")
                }
                // Find the parent cancer cell using our utility function
                if let cancerCell = Self.findParentCancerCell(for: targetEntity, in: context.scene) {
//                    print("Found cancer cell: \(cancerCell.name)")
//                    print("Initial velocity: ")
                    
                    // Removed physics impulse application to disable ADC-cancer cell interactions
                    // while maintaining cell-to-cell collisions
                    
//                    // Apply impulse
//                    cellPhysics.linearVelocity += impactDirection * 2.0
//                    
//                    // Add random angular velocity around Y axis
//                    let randomSign: Float = Bool.random() ? 1.0 : -1.0
//                    cellPhysics.angularVelocity += SIMD3<Float>(0, randomSign * 2.1, 0)
//                    
//                    cancerCell.components[PhysicsMotionComponent.self] = cellPhysics
                    
                } else {
                    print("Could not find parent cancer cell with physics component")
                }

                // Remove from current parent and add to target entity
                entity.removeFromParent()
                targetEntity.addChild(entity)

                // Start antigen retraction
//                print("\n=== Antigen Retraction Setup ===")
                if let offsetEntity = targetEntity.parent {
//                    print("📍 Found offset entity: \(offsetEntity.name)")
                    
                    if var antigenComponent = offsetEntity.components[AntigenComponent.self] {
//                        print("✅ Found AntigenComponent on offset")
                        // Start retraction
                        antigenComponent.isRetracting = true
                        offsetEntity.components[AntigenComponent.self] = antigenComponent
//                        print("🔄 Started antigen retraction")
                        
                        // Start particle emission
                        // if let antigenParent = offsetEntity.parent,
                        //    let particleEntity = antigenParent.findEntity(named: "particle"),
                        //    let emitterEntity = particleEntity.findEntity(named: "ParticleEmitter"),
                        //    var emitter = emitterEntity.components[ParticleEmitterComponent.self] {
                        //     print("��������� Found particle emitter component")
                        //     emitter.isEmitting = true
                        //     emitterEntity.components[ParticleEmitterComponent.self] = emitter
                        //     print("💫 Started particle emission")
                        // } else {
                        //     print("⚠️ Could not find particle emitter in hierarchy")
                        // }
                    } else {
                        print("⚠️ No AntigenComponent found on offset entity")
                    }
                } else {
                    print("⚠️ Could not find offset entity (parent of attachment point)")
                }

                // Align orientation with target and set position with slight offset
                entity.orientation = targetEntity.orientation(relativeTo: nil)
                entity.position = SIMD3<Float>(0, -0.08, 0)
                
                // Scale up animation
                var scaleUpTransform = entity.transform
                scaleUpTransform.scale = SIMD3<Float>(repeating: 1.2)
                
                // Animate scale up and back down
                entity.move(
                    to: scaleUpTransform,
                    relativeTo: entity.parent,
                    duration: 0.15,
                    timingFunction: .easeInOut
                )
                
                // After small delay, scale back to original
                Task {
                    try? await Task.sleep(for: .milliseconds(150))
                    var originalTransform = entity.transform
                    originalTransform.scale = SIMD3<Float>(repeating: 1.0)
                    
                    entity.move(
                        to: originalTransform,
                        relativeTo: entity.parent,
                        duration: 0.15,
                        timingFunction: .easeInOut
                    )
                }
                
                // Stop drone sound and play attach sound
                entity.stopAllAudio()
                if let audioComponent = entity.components[AudioLibraryComponent.self],
                   let attachSound = audioComponent.resources["ADC_Attach.wav"] {
                    // Configure spatial audio characteristics
                    if var spatialAudio = entity.components[SpatialAudioComponent.self] {
                        spatialAudio.directivity = .beam(focus: 1.0)
                        spatialAudio.gain = -6.0
                        entity.components[SpatialAudioComponent.self] = spatialAudio
                    }
                    
                    // Play audio through entity
                    entity.playAudio(attachSound)
                }
                
                // Update component state
                adcComponent.state = .attached
                entity.components[ADCComponent.self] = adcComponent
                
                // Increment hit count for target cell
                if let cellID = adcComponent.targetCellID,
                   let cancerCell = Self.findParentCancerCell(for: targetEntity, in: context.scene),
                   let stateComponent = cancerCell.components[CancerCellStateComponent.self] {
                    
                    // Directly modify the parameters
                    stateComponent.parameters.hitCount += 1
                    stateComponent.parameters.wasJustHit = true
                    
//                    print("Incremented hit count for cell \(cellID) to \(stateComponent.parameters.hitCount)")
                }
            } else {
                // Calculate current position on curve using Bezier curve
                let p = adcComponent.movementProgress
                let distance = length(target - start)
                
                // If we're interpolating to a new target, blend the target position
                let currentTarget: SIMD3<Float>
                if let previousTarget = adcComponent.previousTargetPosition,
                   let newTarget = adcComponent.newTargetPosition,
                   adcComponent.targetInterpolationProgress < 1.0 {
                    // Update interpolation progress
                    adcComponent.targetInterpolationProgress += Float(context.deltaTime / ADCComponent.targetInterpolationDuration)
                    if adcComponent.targetInterpolationProgress >= 1.0 {
                        adcComponent.targetInterpolationProgress = 1.0
                        adcComponent.previousTargetPosition = nil
                        adcComponent.newTargetPosition = nil
                    }
                    
                    // Interpolate target position
                    let t = Self.smoothstep(0, 1, adcComponent.targetInterpolationProgress)
                    currentTarget = Self.mix(previousTarget, newTarget, t: t)
                } else {
                    currentTarget = target
                }
                
                // Calculate control point based on current target
                let midPoint = Self.mix(start, currentTarget, t: 0.5)
                let currentDistance = length(currentTarget - start)
                let heightOffset = currentDistance * 0.5 * arcHeightFactor
                let controlPoint = midPoint + SIMD3<Float>(0, heightOffset, 0)
                
                // Calculate position using quadratic Bezier
                let t1 = 1.0 - p
                let position: SIMD3<Float>
                
                if adcComponent.isTransitioning {
                    // Calculate position on old path
                    let oldMidPoint = Self.mix(start, currentTarget, t: 0.5)
                    let oldDistance = length(currentTarget - start)
                    let oldHeightOffset = oldDistance * 0.5 * arcHeightFactor
                    let oldControlPoint = oldMidPoint + SIMD3<Float>(0, oldHeightOffset, 0)
                    
                    let oldT1 = 1.0 - adcComponent.transitionStartProgress
                    let oldPosition = oldT1 * oldT1 * start + 
                                    2 * oldT1 * adcComponent.transitionStartProgress * oldControlPoint + 
                                    adcComponent.transitionStartProgress * adcComponent.transitionStartProgress * currentTarget
                    
                    // Calculate position on new path
                    let newPosition = t1 * t1 * start + 2 * t1 * p * controlPoint + p * p * currentTarget
                    
                    // Simple linear blend with constant speed
                    position = Self.mix(oldPosition, newPosition, t: adcComponent.transitionProgress)
                    
                    // Update transition progress at constant speed
                    adcComponent.transitionProgress += Float(context.deltaTime / ADCComponent.transitionDuration)
                    
                    if adcComponent.transitionProgress >= 1.0 {
                        adcComponent.isTransitioning = false
                        adcComponent.transitionProgress = 1.0
                    }
                } else {
                    position = t1 * t1 * start + 2 * t1 * p * controlPoint + p * p * currentTarget
                }
                
                // Update position
                entity.position = position
                
                // Set initial orientation only once when movement starts
                if adcComponent.movementProgress <= 0.01 {
                    let direction = normalize(currentTarget - start)
                    Self.setInitialRootOrientation(entity: entity, direction: direction)
                }
                
                // Update protein spin
                Self.updateProteinSpin(entity: entity, deltaTime: context.deltaTime)
                
                // Calculate tangent vector (derivative of Bezier curve)
                let tangentStep1 = (controlPoint - start) * (1 - p)
                let tangentStep2 = (currentTarget - controlPoint) * p
                let tangent = normalize(2 * (tangentStep1 + tangentStep2))
                
                // Debug prints every 10% progress
                if Int(adcComponent.movementProgress * 100) % 10 == 0 {
//                    print("🚀 Movement State:")
//                    print("Entity: \(entity.name)")
//                    print("Progress: \(String(format: "%.2f", adcComponent.movementProgress))")
//                    print("Speed Factor: \(String(format: "%.2f", speedFactor))")
//                    print("Position: (\(String(format: "%.2f, %.2f, %.2f", position.x, position.y, position.z)))")
//                    print("Target: (\(String(format: "%.2f, %.2f, %.2f", currentTarget.x, currentTarget.y, currentTarget.z)))")
                    
                    // Calculate banking parameters
                    let flatTangent = SIMD3<Float>(tangent.x, 0, tangent.z)
                    let normalizedFlatTangent = normalize(flatTangent)
                    _ = cross(normalizedFlatTangent, tangent)
                    _ = abs(tangent.y)
                    
//                    print("🔄 Rotation State:")
//                    print("Position: (\(String(format: "%.2f, %.2f, %.2f", position.x, position.y, position.z)))")
//                    print("Tangent: (\(String(format: "%.2f, %.2f, %.2f", tangent.x, tangent.y, tangent.z)))")
//                    print("Bank Angle: \(String(format: "%.2f", 0))")
//                    print("Vertical Component: \(String(format: "%.2f", verticalComponent))")
//                    print("Current Orientation: \(entity.orientation)")
//                    print("Target Orientation: \(simd_quatf(from: SIMD3<Float>(0, 0, 1), to: tangent))")
                }
                
                // Calculate and apply orientation with spin
                let orientation = Self.calculateOrientation(
                    progress: adcComponent.movementProgress,
                    direction: tangent,
                    deltaTime: context.deltaTime,
                    currentOrientation: entity.orientation,
                    entity: entity
                )
                entity.orientation = orientation
                
            }
            
            // Update component
            entity.components[ADCComponent.self] = adcComponent
            
            // Start drone sound
            // if let audioComponent = entity.components[AudioLibraryComponent.self],
            //    let droneSound = audioComponent.resources["Drones_01.wav"] {
            //     // Configure spatial audio characteristics before playing
            //     if var spatialAudio = entity.components[SpatialAudioComponent.self] {
            //         spatialAudio.directivity = .beam(focus: 1.0)
            //         entity.components[SpatialAudioComponent.self] = spatialAudio
            //     }
                
            //     // Play audio through entity
            //     entity.playAudio(droneSound)
            // }
        }
    }
    
    private static func setInitialRootOrientation(entity: Entity, direction: SIMD3<Float>) {
        let baseOrientation = simd_quatf(from: [0, 0, 1], to: direction)
        entity.orientation = baseOrientation
    }
    
    private static func updateProteinSpin(entity: Entity, deltaTime: TimeInterval) {
        if let proteinComplex = entity.findEntity(named: "antibodyProtein_complex"),
           let adcComponent = entity.components[ADCComponent.self] {
            let spinRotation = simd_quatf(angle: Float(deltaTime) * adcComponent.proteinSpinSpeed, axis: [-1, 0, 0])
            proteinComplex.orientation = proteinComplex.orientation * spinRotation
        }
    }
    
    /// Finds the parent cancer cell entity for an attachment point by querying all cancer cells
    /// and checking if any are ancestors of the given entity
    static func findParentCancerCell(for attachmentPoint: Entity, in scene: Scene) -> Entity? {
//        print("\n=== Finding Parent Cancer Cell ===")
//        print("Starting from attachment point: \(attachmentPoint.name)")
        
        var current = attachmentPoint
        while let parent = current.parent {
//            print("Checking parent: \(parent.name)")
            
            if parent.components[CancerCellStateComponent.self] != nil {
                return parent
            }
            current = parent
        }
        
//        print("❌ No parent cancer cell found")
        return nil
    }
    
    // MARK: - Public API
    
    @MainActor
    public static func startMovement(entity: Entity, from start: SIMD3<Float>, to targetPoint: Entity) {
        guard var adcComponent = entity.components[ADCComponent.self] else {
            print("ERROR: No ADCComponent found on entity")
            return
        }
        
        // Determine if this is a standard or untargeted ADC
        let isUntargeted = targetPoint.components[PositioningComponent.self] != nil
        print("\n=== ADC Movement Setup [\(isUntargeted ? "UNTARGETED" : "STANDARD")] ===")
        
        // Entity Info
        print("\n🔍 Entity Details:")
        print("- Name: \(entity.name)")
        print("- Has Parent: \(entity.parent != nil)")
        print("- Start Position (Local): \(start)")
        print("- Start Position (World): \(entity.position(relativeTo: nil))")
        
        // Target Info
        print("\n🎯 Target Details:")
        print("- Name: \(targetPoint.name)")
        print("- Has Parent: \(targetPoint.parent != nil)")
        print("- Target Position (Local): \(targetPoint.position)")
        print("- Target Position (World): \(targetPoint.position(relativeTo: nil))")
        
        // Add randomization factors first
        adcComponent.arcHeightFactor = Float.random(in: arcHeightRange)
        adcComponent.speedFactor = Float.random(in: speedRange)
        print("\n📊 Movement Parameters:")
        print("- Arc Height Factor: \(adcComponent.arcHeightFactor!)")
        print("- Speed Factor: \(adcComponent.speedFactor!)")
        
        // Path Calculations
        let target = targetPoint.position(relativeTo: nil)
        let worldStart = entity.position(relativeTo: nil)
        let distance = length(target - worldStart)
        print("\n📐 Path Setup:")
        print("- World Start: \(worldStart)")
        print("- World Target: \(target)")
        print("- Direct Distance: \(distance)")
        
        let midPoint = Self.mix(worldStart, target, t: 0.5)
        let heightOffset = distance * 0.5 * adcComponent.arcHeightFactor!
        let controlPoint = midPoint + SIMD3<Float>(0, heightOffset, 0)
        
        print("\n📍 Control Points:")
        print("- Midpoint: \(midPoint)")
        print("- Height Offset: \(heightOffset)")
        print("- Control Point: \(controlPoint)")
        
        // Calculate path length
        let pathLength = Self.quadraticBezierLength(
            p0: worldStart,
            p1: controlPoint,
            p2: target
        )
        print("\n📏 Path Results:")
        print("- Total Path Length: \(pathLength)")
        
        // Setup component
        adcComponent.totalPathLength = pathLength
        adcComponent.state = .moving
        adcComponent.startWorldPosition = worldStart
        adcComponent.movementProgress = 0
        adcComponent.targetEntityID = UInt64(targetPoint.id)
        
        // Update component and position
        entity.components[ADCComponent.self] = adcComponent
        entity.position = start
        
        print("\n🎯 Final Setup:")
        print("- Entity Position (Local): \(entity.position)")
        print("- Entity Position (World): \(entity.position(relativeTo: nil))")
        print("- Movement Progress: \(adcComponent.movementProgress)")
        print("- Path Length: \(adcComponent.totalPathLength)")
        
        // Start drone sound
        if let audioComponent = entity.components[AudioLibraryComponent.self],
           let droneSound = audioComponent.resources["Drones_01.wav"] {
            if var spatialAudio = entity.components[SpatialAudioComponent.self] {
                spatialAudio.directivity = .beam(focus: 1.0)
                entity.components[SpatialAudioComponent.self] = spatialAudio
            }
            entity.playAudio(droneSound)
        }
    }
}
