import RealityKit
import simd

/// A custom system that gently increases the speed of cancer cells that are behind the user.
/// Now uses a head tracking entity that contains a PositioningComponent to get the current head position.
public class CancerCellSpeedBoostSystem: System {
    // Query for entities that have both the PhysicsMotionComponent (for movement) and our movement data component.
    static let query = EntityQuery(where: .has(PhysicsMotionComponent.self) && .has(CancerCellMovementData.self))
    
    // Instead of an AnchorEntity(.camera) we use a new entity with a PositioningComponent.
    private let headEntity: Entity
    
    // Boost parameters.
    private let boostMultiplier: Float = 5.0      // 50% speed boost when behind.
    private let lerpFactor: Float = 0.8           // Interpolation factor to smooth the transition.
    
    public required init(scene: RealityKit.Scene) {
        // Create a new head tracking anchor entity.
        headEntity = Entity()
        // Attach the existing PositioningComponent so that we get the updated device head position.
        headEntity.components.set(PositioningComponent())
        
        if let attackCancerRoot = scene.findEntity(named: "AttackCancerRoot") {
            attackCancerRoot.addChild(headEntity)
        } else {
            print("AttackCancerRoot not found")
        }
    }
    
     public func update(context: SceneUpdateContext) {
        // Iterate over each cancer cell entity.
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var motion = entity.components[PhysicsMotionComponent.self],
                let movementData = entity.components[CancerCellMovementData.self]
            else { continue }
            
            // Calculate the current world positions for the head and the cell.
            let headWorldPos = headEntity.position(relativeTo: nil)
            let cellWorldPos = entity.position(relativeTo: nil)
            
            // Compute the cell's position relative to the head.
            let relativePosition = cellWorldPos - headWorldPos
            
            // In our head coordinate space, -Z is forward.
            // Define zones:
            let behindZone: Float = 0.2      // If relativePosition.z >= 0.2, cell is fully behind.
            let crossingZone: Float = -0.1     // If between 0.2 and -0.1, cell is crossing.
            let frontBlendZone: Float = -1.0   // If between -0.1 and -1.0, blend from full boost to normal.
            var targetMultiplier: Float = 1.0
            var effectiveLerp: Float = 0.0
            
            if relativePosition.z >= behindZone {
                // Fully behind: apply full boost.
                targetMultiplier = boostMultiplier
                effectiveLerp = lerpFactor
            } else if relativePosition.z >= crossingZone {
                // In the crossing zone: maintain full boosted speed (no gradual slowdown yet).
                targetMultiplier = boostMultiplier
                effectiveLerp = 0.0
            } else if relativePosition.z >= frontBlendZone {
                // Gradually blend from boosted to normal speed.
                let t = (abs(relativePosition.z) - abs(crossingZone)) / (abs(frontBlendZone) - abs(crossingZone))
                targetMultiplier = boostMultiplier * (1 - t) + 1.0 * t
                effectiveLerp = lerpFactor * (1 - t)
            } else {
                // Fully in front: no boost.
                targetMultiplier = 1.0
                effectiveLerp = 0.0
            }
            
            // Calculate the intended (base) velocity from the stored movement data.
            let baseVelocity = movementData.baseLinearVelocity
            let desiredVelocity = simd_normalize(baseVelocity) * simd_length(baseVelocity) * targetMultiplier
            
            // Smoothly interpolate between the current velocity and the desired velocity.
            let currentVelocity = motion.linearVelocity
            let newVelocity = simd_mix(currentVelocity, desiredVelocity, SIMD3<Float>(repeating: effectiveLerp))
            
            #if DEBUG
            if relativePosition.z > 0 {
                print("[CancerCellSpeedBoostSystem DEBUG] \(entity.name): relativePosition.z: \(relativePosition.z) => targetMultiplier: \(targetMultiplier), effectiveLerp: \(effectiveLerp)")
                print("[CancerCellSpeedBoostSystem DEBUG] \(entity.name): currentVelocity: \(currentVelocity), desiredVelocity: \(desiredVelocity), newVelocity: \(newVelocity)")
            } else {
                print("[CancerCellSpeedBoostSystem DEBUG] \(entity.name): in front - relativePosition.z: \(relativePosition.z)")
            }
            #endif
            
            // Update the motion component.
            motion.linearVelocity = newVelocity
            entity.components.set(motion)
        }
    }
}
