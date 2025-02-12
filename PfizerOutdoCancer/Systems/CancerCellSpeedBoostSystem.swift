import RealityKit
import simd

/// A system that boosts the speed of cancer cell entities based on their world X and Z positions.
/// The idea is:
/// • If a cell is behind the user (z ≥ 0), it is given full boost.
/// • If a cell is in front (z < 0):
///    – If it is to the left (x < 0), the boost factor is interpolated based on how far left it is.
///    – If it is to the right (x ≥ 0), no boost is applied.
public class CancerCellSpeedBoostSystem: System {
    
    // MARK: - Configuration
    private struct BoostConfig {
        static let maxBoostMultiplier: Float = 2.5   // Full boost multiplies base speed by 2.5
        static let lerpSharpness: Float = 4.0        // Controls how quickly the velocity adjusts
        // For front cells, we interpolate boost over a horizontal range.
        // For example, cells with x ≤ -1.0 (in front left) get full boost; cells with x ≥ 0 get no boost.
        static let frontBoostRange: Float = 1.0
    }
    
    // MARK: - Query Setup
    private static let query = EntityQuery(where:
        .has(CancerCellMovementData.self) &&
        .has(PhysicsMotionComponent.self)
    )
    
    public required init(scene: Scene) {
        // No additional initialization is required.
    }
    
    public func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)
        
        for entity in context.scene.performQuery(Self.query) {
            guard var motion = entity.components[PhysicsMotionComponent.self],
                  let movementData = entity.components[CancerCellMovementData.self] else { continue }
            
            // Get the cell's world position.
            let cellPos = entity.position(relativeTo: nil)
            // Debug print the position.
            print("[Boost Debug] Entity \(entity.name): cellPos = \(cellPos)")
            
            // Determine the desired boost factor.
            let boostFactor: Float
            if cellPos.z >= 0 {
                // Rear cells (z ≥ 0) get full boost.
                boostFactor = BoostConfig.maxBoostMultiplier
                print("[Boost Debug] Entity \(entity.name): Rear cell, applying full boost (\(boostFactor)).")
            } else {
                // For front cells (z < 0), we interpolate based on x.
                // If cellPos.x ≤ -frontBoostRange, then full boost.
                // If cellPos.x ≥ 0, then no boost.
                let normalized: Float = simd_clamp((0 - cellPos.x) / BoostConfig.frontBoostRange, 0, 1)
                boostFactor = 1.0 + (BoostConfig.maxBoostMultiplier - 1.0) * normalized
                print("[Boost Debug] Entity \(entity.name): Front cell, normalized leftness = \(normalized), boostFactor = \(boostFactor)")
            }
            
            // Compute the target (boosted) velocity, preserving the direction.
            let targetVelocity = movementData.baseLinearVelocity * boostFactor
            
            // Smoothly interpolate from the current velocity to the target velocity.
            motion.linearVelocity = simd_mix(
                motion.linearVelocity,
                targetVelocity,
                SIMD3<Float>(repeating: dt * BoostConfig.lerpSharpness)
            )
            
            entity.components.set(motion)
        }
    }
}
