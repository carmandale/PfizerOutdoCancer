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
    private let boostMultiplier: Float = 1.1      // 10% speed boost when behind.
    private let lerpFactor: Float = 0.1           // Interpolation factor to smooth the transition.
    
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
            
            // We assume that in the head coordinate space, -Z is forward.
            // So if relativePosition.z > 0, the cell is behind the user.
            let isBehind = relativePosition.z > 0
            
            // Set the target multiplier—boost if behind, otherwise use normal speed (multiplier 1.0).
            let targetMultiplier: Float = isBehind ? boostMultiplier : 1.0
            
            // Calculate the intended (base) velocity from the stored movement data.
            let baseVelocity = movementData.baseLinearVelocity
            let desiredVelocity = simd_normalize(baseVelocity) * simd_length(baseVelocity) * targetMultiplier
            
            // Smoothly interpolate between the current velocity and the desired velocity.
            let currentVelocity = motion.linearVelocity
            let newVelocity = simd_mix(currentVelocity, desiredVelocity, SIMD3<Float>(repeating: lerpFactor))
            motion.linearVelocity = newVelocity
            
            // Update the entity's motion component.
            entity.components.set(motion)
        }
    }
}
