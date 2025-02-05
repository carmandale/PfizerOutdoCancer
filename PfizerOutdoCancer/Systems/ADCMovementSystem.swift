// PfizerOutdoCancer/Systems/ADCMovementSystem.swift
// Revised ADCMovementSystem.swift

import RealityKit
import Foundation
import RealityKitContent

@MainActor
public class ADCMovementSystem: System {
    // MARK: - Queries and Constants
    
    /// Query for entities with an ADC component
    static let query = EntityQuery(where: .has(ADCComponent.self))
    
    // Movement parameters
    static let numSteps: Double = 120
    static let baseArcHeight: Float = 1.2
    static let arcHeightRange: ClosedRange<Float> = 0.6...1.2
    static let baseStepDuration: TimeInterval = 0.016  // ~60fps
    static let speedRange: ClosedRange<Float> = 1.2...3.0
    static let totalDuration: TimeInterval = numSteps * baseStepDuration
    static let minDistance: Float = 0.5
    static let maxDistance: Float = 3.0
    
    // Rotation parameters
    static let rotationSmoothingFactor: Float = 12.0
    static let maxBankAngle: Float = .pi / 8
    static let bankingSmoothingFactor: Float = 6.0
    
    // Acceleration parameters
    static let accelerationPhase: Float = 0.2
    static let decelerationPhase: Float = 0.2
    static let minSpeedMultiplier: Float = 0.4
    
    // Retargeting parameters
    private static let retargetDuration: Float = 0.5
    static let numLookupSamples: Int = 100
    
    // MARK: - Initialization
    required public init(scene: Scene) { }
    
    // MARK: - Update Loop
    public func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var adcComponent = entity.components[ADCComponent.self],
                  adcComponent.state == .moving,
                  let start = adcComponent.startWorldPosition,
                  let targetID = adcComponent.targetEntityID else { continue }
            
            // Find target entity by its ID.
            let query = EntityQuery(where: .has(AttachmentPoint.self))
            let entities = context.scene.performQuery(query)
            guard let targetEntity = entities.first(where: { $0.id == Entity.ID(targetID) }) else {
                print("⚠️ Target entity not found - aborting ADC movement")
                adcComponent.state = .idle
                entity.components[ADCComponent.self] = adcComponent
                continue
            }
            
            // Validate target before proceeding.
            if !Self.validateTarget(targetEntity, adcComponent, in: context.scene) {
                print("⚠️ Target no longer valid - attempting to find new target")
                if Self.retargetADC(entity, &adcComponent, currentPosition: entity.position(relativeTo: nil), in: context.scene) {
                    entity.components[ADCComponent.self] = adcComponent
                    continue
                } else {
                    print("⚠️ No valid targets found - resetting ADC")
                    Self.resetADC(entity: entity, component: &adcComponent)
                    continue
                }
            }
            
            // Get the target position, handling interpolation if needed
            var targetPosition = targetEntity.position(relativeTo: nil)
            
            // If we're interpolating between targets, blend the target position
            if let previousTarget = adcComponent.previousTargetPosition,
               let newTarget = adcComponent.newTargetPosition {
                // Update interpolation progress
                adcComponent.targetInterpolationProgress += Float(context.deltaTime / ADCComponent.targetInterpolationDuration)
                
                // When interpolation is complete, update the path
                if adcComponent.targetInterpolationProgress >= 1.0 {
                    adcComponent.targetInterpolationProgress = 1.0
                    
                    print("\n=== Path Update Before Recalculation ===")
                    print("Current Position: \(entity.position(relativeTo: nil))")
                    print("Start Position: \(start)")
                    print("Previous Target: \(previousTarget)")
                    print("New Target: \(newTarget)")
                    print("Current Traveled Distance: \(adcComponent.traveledDistance)")
                    print("Previous Path Length: \(adcComponent.pathLength)")
                    
                    // Calculate distances for scaling decision
                    let oldTargetDistance = length(previousTarget - start)
                    let newTargetDistance = length(newTarget - start)
                    
                    print("\n=== Distance Comparison ===")
                    print("Old target distance: \(oldTargetDistance)")
                    print("New target distance: \(newTargetDistance)")
                    
                    // Scale traveled distance if new target is closer
                    var newTraveledDistance = adcComponent.traveledDistance
                    if newTargetDistance < oldTargetDistance {
                        newTraveledDistance = (adcComponent.traveledDistance / oldTargetDistance) * newTargetDistance
                        print("Scaling traveled distance: \(adcComponent.traveledDistance) -> \(newTraveledDistance)")
                    } else {
                        print("New target is farther - preserving absolute traveled distance")
                    }
                    
                    // Calculate new path
                    let distance = length(newTarget - start)
                    let midPoint = Self.mix(start, newTarget, t: 0.5)
                    let arcHeightFactor = adcComponent.arcHeightFactor ?? 1.0
                    let heightOffset = distance * 0.5 * arcHeightFactor
                    let controlPoint = midPoint + SIMD3<Float>(0, heightOffset, 0)
                    
                    // Build new lookup table
                    let lookup = Self.buildLookupTableForQuadraticBezier(
                        start: start,
                        control: controlPoint,
                        end: newTarget,
                        samples: Self.numLookupSamples
                    )
                    
                    let newPathLength = lookup.last ?? 0.0
                    
                    print("\n=== Path Update After Recalculation ===")
                    print("New Path Length: \(newPathLength)")
                    print("Traveled Distance (updated): \(newTraveledDistance)")
                    print("New Progress: \(newTraveledDistance / newPathLength)")
                    print("Distance from start to target: \(distance)")
                    
                    // Verify the new path is valid
                    if newPathLength <= 0.0 {
                        print("⚠️ Invalid new path length!")
                        continue
                    }
                    
                    // Update component with new path data
                    adcComponent.lookupTable = lookup
                    adcComponent.pathLength = newPathLength
                    adcComponent.traveledDistance = newTraveledDistance
                    adcComponent.wasRetargeted = true
                    adcComponent.previousTargetPosition = nil
                    adcComponent.newTargetPosition = nil
                    
                    print("✅ Path update complete - ADC will continue to new target")
                }
                
                // Interpolate target position for this frame
                let t = Self.smoothstep(0, 1, adcComponent.targetInterpolationProgress)
                targetPosition = Self.mix(previousTarget, newTarget, t: t)
            }
            
            // Calculate path parameters based on current target position
            let distance = length(targetPosition - start)
            let midPoint = Self.mix(start, targetPosition, t: 0.5)
            let arcHeightFactor = adcComponent.arcHeightFactor ?? 1.0
            let heightOffset = distance * 0.5 * arcHeightFactor
            let controlPoint = midPoint + SIMD3<Float>(0, heightOffset, 0)
            
            // Update lookup table if needed (first frame or after retargeting)
            if adcComponent.lookupTable == nil {
                let lookup = Self.buildLookupTableForQuadraticBezier(start: start, control: controlPoint, end: targetPosition, samples: Self.numLookupSamples)
                adcComponent.lookupTable = lookup
                adcComponent.pathLength = lookup.last ?? 0.0
                adcComponent.traveledDistance = 0.0
            }
            
            // Calculate effective speed and update traveled distance
            let speedFactor = adcComponent.speedFactor ?? 1.0
            let baseSpeed = adcComponent.pathLength / Float(Self.totalDuration)
            
            // Calculate speed multiplier based on acceleration/deceleration
            let normalizedProgress = (adcComponent.pathLength > 0) ? (adcComponent.traveledDistance / adcComponent.pathLength) : 0
            let speedMultiplier: Float
            if normalizedProgress < Self.accelerationPhase {
                let t = normalizedProgress / Self.accelerationPhase
                speedMultiplier = Self.mix(Self.minSpeedMultiplier, 1.0, t: Self.smoothstep(0, 1, t))
            } else if normalizedProgress > (1.0 - Self.decelerationPhase) {
                let t = (normalizedProgress - (1.0 - Self.decelerationPhase)) / Self.decelerationPhase
                speedMultiplier = Self.mix(1.0, Self.minSpeedMultiplier, t: Self.smoothstep(0, 1, t))
            } else {
                speedMultiplier = 1.0
            }
            
            let effectiveSpeed = baseSpeed * speedFactor * speedMultiplier
            adcComponent.traveledDistance += effectiveSpeed * Float(context.deltaTime)
            adcComponent.traveledDistance = min(adcComponent.traveledDistance, adcComponent.pathLength)
            
            // Check for retargeting at 40% for untargeted ADCs
            let currentNormalizedProgress = (adcComponent.pathLength > 0) ? (adcComponent.traveledDistance / adcComponent.pathLength) : 0
            if currentNormalizedProgress >= 0.4 {
                if targetEntity.components[PositioningComponent.self] != nil {
                    print("🎯 ADC at 40% to headPosition - attempting to find cancer cell target")
                    if Self.retargetADC(entity, &adcComponent, currentPosition: entity.position(relativeTo: nil), in: context.scene) {
                        entity.components[ADCComponent.self] = adcComponent
                        // Remove the headPosition entity and its debug sphere.
                        targetEntity.removeFromParent()
                        print("✨ Removed headPosition entity after successful retarget")
                        continue
                    }
                    // If retargeting fails, just continue to the headPosition
                    print("⚠️ No suitable cancer cell targets found - continuing to headPosition")
                }
            }
            
            // Calculate current position on the path
            let tMapped = Self.lookupParameter(forDistance: adcComponent.traveledDistance, lookup: adcComponent.lookupTable ?? [])
            
            // Break down quadratic Bézier calculation into steps
            let t1 = 1.0 - tMapped
            let t2 = tMapped
            
            // Calculate each term separately
            let term1 = start * (t1 * t1)
            let term2 = controlPoint * (2 * t1 * t2)
            let term3 = targetPosition * (t2 * t2)
            
            // Sum the terms to get final position
            let position = term1 + term2 + term3
            entity.position = position
            
            // Calculate tangent vector components separately
            let tangentStart = (controlPoint - start) * (1 - tMapped)
            let tangentEnd = (targetPosition - controlPoint) * tMapped
            let tangent = normalize(2 * (tangentStart + tangentEnd))
            
            // Update orientation
            let orientation = Self.calculateOrientation(
                progress: tMapped,
                direction: tangent,
                deltaTime: context.deltaTime,
                currentOrientation: entity.orientation,
                entity: entity
            )
            entity.orientation = orientation
            
            // Save updated component
            entity.components[ADCComponent.self] = adcComponent
            
            // Handle completion
            if adcComponent.hasCollided {
                print("\n=== ADC Path Completion ===")
                print("Final Progress: \(tMapped)")
                print("Total Distance Traveled: \(adcComponent.traveledDistance)")
                print("Path Length: \(adcComponent.pathLength)")
                print("Start Position: \(start)")
                print("Final Position: \(position)")
                print("Target Position: \(targetPosition)")
                
                // Trigger a hit-scale animation on the parent cancer cell
                if let cancerCell = Self.findParentCancerCell(for: targetEntity, in: context.scene) {
                    print("✅ Found parent cancer cell - triggering hit animation")
                    Task { @MainActor in
                        await cancerCell.hitScaleAnimation(
                            intensity: 0.95,
                            duration: 0.2,
                            scaleReduction: 0.05
                        )
                    }
                } else {
                    print("⚠️ Could not find parent cancer cell for hit animation")
                }
                
                print("\n=== ADC Attachment Process ===")
                // Remove ADC from its current parent and prepare for attachment
                let previousParent = entity.parent?.name ?? "none"
                entity.removeFromParent()
                
                // Compute and validate landing transform
                let landingTransform = Self.computeLandingTransform(for: entity, with: targetEntity)
                if Self.validateLandingTransform(landingTransform) {
                    // Add as child with computed transform
                    targetEntity.addChild(entity)
                    entity.transform = landingTransform
                    
                    print("✅ Applied landing transform successfully")
                } else {
                    // Fallback to simple attachment if transform is invalid
                    targetEntity.addChild(entity)
                    entity.position = SIMD3<Float>(0, -0.08, 0)
                    entity.orientation = targetEntity.orientation(relativeTo: nil)
                    print("⚠️ Using fallback attachment due to invalid landing transform")
                }
                
                print("🔄 Reparented ADC:")
                print("Previous Parent: \(previousParent)")
                print("New Parent: \(targetEntity.name)")
                
                // Trigger antigen retraction
                if let offsetEntity = targetEntity.parent {
                    if var antigenComponent = offsetEntity.components[AntigenComponent.self] {
                        antigenComponent.isRetracting = true
                        offsetEntity.components[AntigenComponent.self] = antigenComponent
                    }
                }
                
                // Scale-up animation
                var scaleUpTransform = entity.transform
                scaleUpTransform.scale = SIMD3<Float>(repeating: 1.2)
                entity.move(
                    to: scaleUpTransform,
                    relativeTo: entity.parent,
                    duration: 0.15,
                    timingFunction: .easeInOut
                )
                
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
                
                // Handle audio
                entity.stopAllAudio()
                if let audioComponent = entity.components[AudioLibraryComponent.self],
                   let attachSound = audioComponent.resources["ADC_Attach.wav"] {
                    if var spatialAudio = entity.components[SpatialAudioComponent.self] {
                        spatialAudio.directivity = .beam(focus: 1.0)
                        spatialAudio.gain = -6.0
                        entity.components[SpatialAudioComponent.self] = spatialAudio
                    }
                    entity.playAudio(attachSound)
                }
                
                // Update ADC state
                adcComponent.state = .attached
                entity.components[ADCComponent.self] = adcComponent
                print("✅ ADC state updated to attached")
                
                // Update cell hit count
                if let cellID = adcComponent.targetCellID,
                   let cancerCell = Self.findParentCancerCell(for: targetEntity, in: context.scene),
                   let stateComponent = cancerCell.components[CancerCellStateComponent.self] {
                    let previousHits = stateComponent.parameters.hitCount
                    stateComponent.parameters.hitCount += 1
                    stateComponent.parameters.wasJustHit = true
                    print("📊 Updated cell hit count:")
                    print("Cell ID: \(cellID)")
                    print("Previous Hits: \(previousHits)")
                    print("New Hits: \(stateComponent.parameters.hitCount)")
                    print("Required Hits: \(stateComponent.parameters.requiredHits)")
                } else {
                    print("⚠️ Could not update hit count - missing required components")
                }
                
                print("✅ ADC completion process finished successfully")
                continue
            }
            
            // Set the initial orientation on the first frame.
            if adcComponent.traveledDistance <= 0.01 {
                let direction = simd_normalize(targetPosition - start)
                Self.setInitialRootOrientation(entity: entity, direction: direction)
            }
            
            // Update any additional per-frame behavior (like protein spin).
            Self.updateProteinSpin(entity: entity, deltaTime: context.deltaTime)
            
            // Save updated component.
            entity.components[ADCComponent.self] = adcComponent
        }
    }
    
    // MARK: - Helper Functions
    
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
    
    /// Replaces the old `startMovement` method to initialize the lookup table and arc-length parameters.
    @MainActor
    public static func startMovement(entity: Entity, from start: SIMD3<Float>, to targetPoint: Entity) {
        guard var adcComponent = entity.components[ADCComponent.self] else {
            print("ERROR: No ADCComponent found on entity")
            return
        }
        
        adcComponent.state = .moving
        adcComponent.startWorldPosition = start
        adcComponent.traveledDistance = 0.0
        adcComponent.targetEntityID = UInt64(targetPoint.id)
        
        adcComponent.arcHeightFactor = Float.random(in: arcHeightRange)
        adcComponent.speedFactor = Float.random(in: speedRange)
        
        let target = targetPoint.position(relativeTo: nil)
        let distance = length(target - start)
        let midPoint = mix(start, target, t: 0.5)
        let heightOffset = distance * 0.5 * (adcComponent.arcHeightFactor ?? 1.0)
        let controlPoint = midPoint + SIMD3<Float>(0, heightOffset, 0)
        
        let lookup = Self.buildLookupTableForQuadraticBezier(start: start, control: controlPoint, end: target, samples: Self.numLookupSamples)
        adcComponent.lookupTable = lookup
        adcComponent.pathLength = lookup.last ?? 0.0
        
        entity.components[ADCComponent.self] = adcComponent
        entity.position = start
        
        // Start drone sound.
        if let audioComponent = entity.components[AudioLibraryComponent.self],
           let droneSound = audioComponent.resources["Drones_01.wav"] {
            if var spatialAudio = entity.components[SpatialAudioComponent.self] {
                spatialAudio.directivity = .beam(focus: 1.0)
                entity.components[SpatialAudioComponent.self] = spatialAudio
            }
            entity.playAudio(droneSound)
        }
    }
    
    // (The resetADC function is defined in its separate extension file.)
}
