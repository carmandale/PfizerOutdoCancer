import RealityKit
import simd

@Observable
public class CancerCellSpeedBoostSystem: System {
    // MARK: - Configuration
    private struct BoostConfig {
        static let leftActivationX: Float = -0.7    // Activate boost when X < -0.7m (far left)
        static let maxBoostMultiplier: Float = 2.5   // 150% speed increase
        static let lerpSharpness: Float = 4.0        // Quick response to boost
    }
    
    // MARK: - System Setup
    private static let query = EntityQuery(where: 
        .has(CancerCellMovementData.self) && 
        .has(PhysicsMotionComponent.self)
    )
    
    public required init(scene: Scene) {}  // No debug visualization
    
    public func update(context: SceneUpdateContext) {
        let deltaTime = Float(context.deltaTime)
        
        for entity in context.scene.performQuery(Self.query) {
            guard var motion = entity.components[PhysicsMotionComponent.self],
                  let movementData = entity.components[CancerCellMovementData.self] else { continue }
            
            let cellPos = entity.position(relativeTo: nil)
            
            // Only activate boost when cell is in left quadrant
            guard cellPos.x < BoostConfig.leftActivationX else {
                // Gradually return to normal speed when exiting boost zone
                motion.linearVelocity = simd_mix(
                    motion.linearVelocity,
                    movementData.baseLinearVelocity,
                    SIMD3<Float>(repeating: deltaTime * BoostConfig.lerpSharpness)
                )
                continue
            }
            
            // Calculate boost intensity based on how far left the cell is
            let leftness = 1 - min(abs(cellPos.x) / 2.0, 1.0) // 0-1 scale
            let boostFactor = 1.0 + (BoostConfig.maxBoostMultiplier - 1.0) * leftness
            
            // Preserve orbital direction while applying speed boost
            let boostedVelocity = movementData.baseLinearVelocity * boostFactor
            
            // Apply velocity change
            motion.linearVelocity = simd_mix(
                motion.linearVelocity,
                boostedVelocity,
                SIMD3<Float>(repeating: deltaTime * BoostConfig.lerpSharpness)
            )
            
            entity.components.set(motion)
        }
    }
}