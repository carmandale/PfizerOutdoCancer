import RealityKit
import simd

public class CancerCellSpeedBoostSystem: System {
    // Query for entities that have both the CancerCellMovementData (for orbiting)
    // and a PhysicsMotionComponent (for current velocity) components.
    static let query = EntityQuery(where: .has(CancerCellMovementData.self) && .has(PhysicsMotionComponent.self))
    
    // A head tracking entity to get the current head position.
    private let headEntity: Entity
    
    // Boost parameters:
    // When a cell’s relative X is less than leftZoneThreshold, we boost its speed.
    private let leftZoneThreshold: Float = -0.2  // Adjust as needed (in world units)
    private let boostMultiplier: Float = 5.0       // Full boost multiplier when fully left
    private let lerpFactor: Float = 0.8            // Controls smoothing of velocity changes
    
    public required init(scene: Scene) {
        // Create the head tracking entity.
        headEntity = Entity()
        headEntity.components.set(PositioningComponent())
        
        // Attach the head tracking entity if AttackCancerRoot exists.
        if let attackCancerRoot = scene.findEntity(named: "AttackCancerRoot") {
            attackCancerRoot.addChild(headEntity)
        } else {
            // In non-playing phases, the root might not be present.
            // We silently ignore to prevent log spam.
        }
    }
    
    public func update(context: SceneUpdateContext) {
        // Only run this system when AttackCancerRoot is present
        guard let _ = context.scene.findEntity(named: "AttackCancerRoot") else { return }
        
        let deltaTime = Float(context.deltaTime)
        
        for entity in context.scene.performQuery(Self.query) {
            guard var motion = entity.components[PhysicsMotionComponent.self],
                  let movementData = entity.components[CancerCellMovementData.self] else { continue }
            
            // Compute the cell's relative position with respect to the head.
            let headWorldPos = headEntity.position(relativeTo: nil)
            let cellWorldPos = entity.position(relativeTo: nil)
            let relativePos = cellWorldPos - headWorldPos
            
            // Determine the target boost multiplier.
            // In this version, if the cell is sufficiently on the left, we apply the full boost.
            // (You could also implement a blending zone if desired.)
            var targetMultiplier: Float = 1.0
            if relativePos.x < leftZoneThreshold {
                targetMultiplier = boostMultiplier
            }
            
            // Retrieve the cell's base orbit velocity (the direction of its orbit).
            let baseVelocity = movementData.baseLinearVelocity
            // Compute the desired velocity by scaling the base velocity by the target multiplier.
            let desiredVelocity = simd_normalize(baseVelocity) * (simd_length(baseVelocity) * targetMultiplier)
            
            // Smoothly blend between the current velocity and the desired velocity.
            // Multiplying lerpFactor by deltaTime helps keep the interpolation frame-rate independent.
            let t = lerpFactor * deltaTime
            let newVelocity = simd_mix(motion.linearVelocity, desiredVelocity, SIMD3<Float>(repeating: t))
            motion.linearVelocity = newVelocity
            
            // Apply only very mild angular damping so that cells don't spin excessively,
            // but still retain some orbital rotation.
            let angularDampingFactor: Float = 0.98  // Adjust closer to 1.0 for less damping.
            motion.angularVelocity *= angularDampingFactor
            
            entity.components.set(motion)
        }
    }
}