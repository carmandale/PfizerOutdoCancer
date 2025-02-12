import RealityKit
import simd
import UIKit

public class CancerCellSpeedBoostSystem: System {
    // Query for entities with both CancerCellMovementData and PhysicsMotionComponent.
    static let query = EntityQuery(where: .has(CancerCellMovementData.self) && .has(PhysicsMotionComponent.self))
    
    // Boost parameters:
    // We assume negative Z is in front. Therefore, a cell with a world Z > 0 is behind the user.
    // A cell is in boost mode if it is behind (z > 0) and its x value is less than leftZoneThreshold (i.e. sufficiently left).
    private let leftZoneThreshold: Float = 0.5
    private let boostMultiplier: Float = 30.0
    
    // Separate lerp factors for acceleration and deceleration.
    private let accelerationLerp: Float = 1.0   // Fast acceleration when boost is active.
    private let decelerationLerp: Float = 0.3   // Slower deceleration when returning to base speed.
    
    // Dictionary to store each entity's original materials for visual feedback.
    private var originalMaterials: [Entity.ID: [Material]] = [:]
    
    public required init(scene: Scene) {
        // We no longer require a head tracking entity.
    }
    
    public func update(context: SceneUpdateContext) {
        let deltaTime = Float(context.deltaTime)
        
        for entity in context.scene.performQuery(Self.query) {
            guard var motion = entity.components[PhysicsMotionComponent.self],
                  let movementData = entity.components[CancerCellMovementData.self] else { continue }
            
            // Get the cell's world position relative to the scene's origin.
            let cellPos = entity.position(relativeTo: nil)
            
            // Debug: Print the cell's absolute position.
            print("[Boost Debug] Entity \(entity.name): cellPos = \(cellPos)")
            
            // Determine if the cell is in the boost zone:
            // - It is "behind" if cellPos.z > 0 (since negative Z is in front).
            // - It is on the left if cellPos.x < leftZoneThreshold.
            let isInBoostZone = (cellPos.z > 0) && (cellPos.x > leftZoneThreshold)
            print("[Boost Debug] Entity \(entity.name): isInBoostZone = \(isInBoostZone)")
            
            // Set the target speed multiplier.
            let targetMultiplier: Float = isInBoostZone ? boostMultiplier : 1.0
            
            // Choose the appropriate lerp factor: fast when accelerating (boosting) and slower when decelerating.
            let lerpToUse: Float = (targetMultiplier > 1.0 ? accelerationLerp : decelerationLerp)
            let t = lerpToUse * deltaTime
            
            // Compute the desired velocity by taking the base orbit velocity, preserving its direction,
            // and scaling its magnitude by the target multiplier.
            let baseVelocity = movementData.baseLinearVelocity
            let desiredVelocity = simd_normalize(baseVelocity) * (simd_length(baseVelocity) * targetMultiplier)
            
            // Smoothly interpolate the current velocity toward the desired velocity.
            let newVelocity = simd_mix(motion.linearVelocity, desiredVelocity, SIMD3<Float>(repeating: t))
            motion.linearVelocity = newVelocity
            entity.components.set(motion)
            
            // Debug material change for visual feedback.
            if var modelComponent = entity.components[ModelComponent.self] {
                if isInBoostZone {
                    // Store original materials if not already stored.
                    if originalMaterials[entity.id] == nil {
                        originalMaterials[entity.id] = modelComponent.materials
                    }
                    // Change material to a red SimpleMaterial.
                    let boostMaterial = SimpleMaterial(color: .blue, isMetallic: false)
                    modelComponent.materials = [boostMaterial]
                    entity.components.set(modelComponent)
                    print("[Boost Debug] Entity \(entity.name): In boost mode. Material changed to red.")
                } else {
                    // If not in boost mode, restore original materials if available.
                    if let original = originalMaterials[entity.id] {
                        modelComponent.materials = original
                        entity.components.set(modelComponent)
                        originalMaterials.removeValue(forKey: entity.id)
                        print("[Boost Debug] Entity \(entity.name): Not in boost mode. Material restored.")
                    }
                }
            }
        }
    }
}
