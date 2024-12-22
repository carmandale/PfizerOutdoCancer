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
    
    // Spin configuration
    static let proteinSpinSpeed: Float = Float.random(in: 8.0...10.0)  // Random spin speed between 8-15
    
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
                // Acceleration phase: gradually increase from minSpeedMultiplier to 1.0
                let t = adcComponent.movementProgress / Self.accelerationPhase
                speedMultiplier = Self.mix(Self.minSpeedMultiplier, 1.0, t: Self.smoothstep(0, 1, t))
                if Int(t * 100) % 50 == 0 { // Print at 0% and 50% of acceleration
//                    print("🏃‍♂️ Acceleration - Speed Multiplier: \(String(format: "%.2f", speedMultiplier))")
                }
            } else if adcComponent.movementProgress > (1.0 - Self.decelerationPhase) {
                // Deceleration phase: gradually decrease from 1.0 to minSpeedMultiplier
                let t = (adcComponent.movementProgress - (1.0 - Self.decelerationPhase)) / Self.decelerationPhase
                speedMultiplier = Self.mix(1.0, Self.minSpeedMultiplier, t: Self.smoothstep(0, 1, t))
                if Int(t * 100) % 50 == 0 { // Print at 0% and 50% of deceleration
//                    print("🛑 Deceleration - Speed Multiplier: \(String(format: "%.2f", speedMultiplier))")
                }
            } else {
                // Cruising phase: full speed
                speedMultiplier = 1.0
            }
            
            // Debug print for movement phase and speed (at key points)
            if Int(adcComponent.movementProgress * 100) % 25 == 0 { // Print at 0%, 25%, 50%, 75%
//                print("\n🚀 === ADC Progress [Entity: \(entity.name)] ===")
//                print("⏱️ Progress: \(String(format: "%.2f", adcComponent.movementProgress))")
//                print("💨 Speed Factor: \(String(format: "%.2f", speedFactor))")
//                print("🎚️ Speed Multiplier: \(String(format: "%.2f", speedMultiplier))")
            }
            
            // Update progress with randomized speed and phase-based multiplier
            adcComponent.movementProgress += Float(context.deltaTime / (Self.baseStepDuration * TimeInterval(1/speedFactor) * Self.numSteps)) * speedMultiplier
            
            if adcComponent.movementProgress >= 1.0 {
                // Movement complete
//                print("\n=== ADC Impact ===")
                let impactDirection = normalize(target - start)
//                print("💥 Direction: (\(String(format: "%.2f, %.2f, %.2f", impactDirection.x, impactDirection.y, impactDirection.z)))")
                
                // Find the parent cancer cell using our utility function
                if let cancerCell = Self.findParentCancerCell(for: targetEntity, in: context.scene),
                   var cellPhysics = cancerCell.components[PhysicsMotionComponent.self] {
//                    print("Found cancer cell: \(cancerCell.name)")
//                    print("Initial velocity: \(cellPhysics.linearVelocity)")
                    
                    // Apply impulse
                    cellPhysics.linearVelocity += impactDirection * 0.05
                    
                    // Add random angular velocity around Y axis
                    let randomSign: Float = Bool.random() ? 1.0 : -1.0
                    cellPhysics.angularVelocity += SIMD3<Float>(0, randomSign * 0.1, 0)
                    
//                    print("New velocity: \(cellPhysics.linearVelocity)")
//                    print("New angular velocity: \(cellPhysics.angularVelocity)")
                    
                    cancerCell.components[PhysicsMotionComponent.self] = cellPhysics
//                    print("Updated physics on cancer cell")
                    
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
                    
                    print("Incremented hit count for cell \(cellID) to \(stateComponent.parameters.hitCount)")
                }
            } else {
                // Calculate current position on curve using Bezier curve
                let p = adcComponent.movementProgress
                let distance = length(target - start)
                let midPoint = Self.mix(start, target, t: 0.5)
                let heightOffset = distance * 0.5 * arcHeightFactor
                let controlPoint = midPoint + SIMD3<Float>(0, heightOffset, 0)
                
                // Quadratic Bezier formula: B(t) = (1-t)²P0 + 2(1-t)tP1 + t²P2
                let t1 = 1.0 - p
                let position = t1 * t1 * start + 2 * t1 * p * controlPoint + p * p * target
                
                // Update position
                entity.position = position
                
                // Set initial orientation only once when movement starts
                if adcComponent.movementProgress <= 0.01 {
                    let direction = normalize(target - start)
                    Self.setInitialRootOrientation(entity: entity, direction: direction)
                }
                
                // Update protein spin
                Self.updateProteinSpin(entity: entity, deltaTime: context.deltaTime)
                
                // Calculate tangent vector (derivative of Bezier curve)
                let tangentStep1 = (controlPoint - start) * (1 - p)
                let tangentStep2 = (target - controlPoint) * p
                let tangent = normalize(2 * (tangentStep1 + tangentStep2))
                
                // Debug prints every 10% progress
                if Int(adcComponent.movementProgress * 100) % 10 == 0 {
//                    print("🚀 Movement State:")
//                    print("Entity: \(entity.name)")
//                    print("Progress: \(String(format: "%.2f", adcComponent.movementProgress))")
//                    print("Speed Factor: \(String(format: "%.2f", speedFactor))")
//                    print("Position: (\(String(format: "%.2f, %.2f, %.2f", position.x, position.y, position.z)))")
//                    print("Target: (\(String(format: "%.2f, %.2f, %.2f", target.x, target.y, target.z)))")
                    
                    // Calculate banking parameters
                    let flatTangent = SIMD3<Float>(tangent.x, 0, tangent.z)
                    let normalizedFlatTangent = normalize(flatTangent)
                    let crossProduct = cross(normalizedFlatTangent, tangent)
                    let verticalComponent = abs(tangent.y)
                    
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
        }
    }
    
    private static func setInitialRootOrientation(entity: Entity, direction: SIMD3<Float>) {
        let baseOrientation = simd_quatf(from: [0, 0, 1], to: direction)
        entity.orientation = baseOrientation
    }
    
    private static func updateProteinSpin(entity: Entity, deltaTime: TimeInterval) {
        if let proteinComplex = entity.findEntity(named: "antibodyProtein_complex") {
            let spinRotation = simd_quatf(angle: Float(deltaTime) * proteinSpinSpeed, axis: [-1, 0, 0])
            proteinComplex.orientation = proteinComplex.orientation * spinRotation
        }
    }
    
    /// Finds the parent cancer cell entity for an attachment point by querying all cancer cells
    /// and checking if any are ancestors of the given entity
    static func findParentCancerCell(for attachmentPoint: Entity, in scene: Scene) -> Entity? {
        print("\n=== Finding Parent Cancer Cell ===")
        print("Starting from attachment point: \(attachmentPoint.name)")
        
        var current = attachmentPoint
        while let parent = current.parent {
            print("Checking parent: \(parent.name)")
            
            if let stateComponent = parent.components[CancerCellStateComponent.self] {
                print("✅ Found cancer cell with state component")
                print("Cell ID: \(String(describing: stateComponent.parameters.cellID))")
                print("Hit Count: \(stateComponent.parameters.hitCount)")
                print("Is Destroyed: \(stateComponent.parameters.isDestroyed)")
                return parent
            }
            current = parent
        }
        
        print("❌ No parent cancer cell found")
        return nil
    }
    
    // MARK: - Public API
    
    @MainActor
    public static func startMovement(entity: Entity, from start: SIMD3<Float>, to targetPoint: Entity) {
//        print("\n=== Starting ADC Movement ===")
//        print("ADC Entity: \(entity.name)")
//        print("Start Position: \(start)")
//        print("Target Entity: \(targetPoint.name)")
//        print("Target Position: \(targetPoint.position(relativeTo: nil))")
//        print("ADC Components: \(entity.components)")
        
        guard var adcComponent = entity.components[ADCComponent.self] else {
            print("ERROR: No ADCComponent found on entity")
            return
        }
        
        // Set up movement
        adcComponent.state = .moving
        adcComponent.startWorldPosition = start
        adcComponent.movementProgress = 0
        adcComponent.targetEntityID = UInt64(targetPoint.id)
        
        // Add randomization factors
        adcComponent.arcHeightFactor = Float.random(in: arcHeightRange)
        adcComponent.speedFactor = Float.random(in: speedRange)
        
        // Update the component
        entity.components[ADCComponent.self] = adcComponent
        
        // Initial position
        entity.position = start
        
        // Start drone sound
        if let audioComponent = entity.components[AudioLibraryComponent.self],
           let droneSound = audioComponent.resources["Drones_01.wav"] {
            entity.playAudio(droneSound)
        }
    }
}
