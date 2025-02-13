import RealityKit
import simd

public class CancerCellSpeedBoostSystem: System {

    private struct BoostConfig {
        static let maxBoostMultiplier: Float = 20.5
        static let lerpSharpness: Float = 4.0
        static let gravityMagnitude: Float = 0.1
    }
    
    private static let query = EntityQuery(where:
        .has(PhysicsMotionComponent.self)
    )
    
    public required init(scene: Scene) {}
    
    public func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)
        
        // If you have a specific user Entity, get its position.
        // Otherwise assume the user is at (0,0,0).
        let userPos = SIMD3<Float>(0, 0, 0)
        
        for entity in context.scene.performQuery(Self.query) {
            guard var motion = entity.components[PhysicsMotionComponent.self] else { continue }
            
            // 1) Current offset from user
            let worldPos = entity.position(relativeTo: nil)
            let offset   = worldPos - userPos
            
            // 2) Radius + angle
            let radius = simd_length(offset)
            // angle in [-π, π], with angle=0 meaning “behind user” if we do atan2(x,z).
            // (Because if x=0 and z>0 => angle=0 => that is “back” in your coordinate scheme.)
            let angle  = atan2(offset.x, offset.z)
            
            // 3) Recompute tangential orbit direction each frame so they keep circling
            let orbitDirection = SIMD3<Float>(
                cos(angle),
                0,
                -sin(angle)
            )
            
            // 4) Base orbital speed
            let baseOrbitSpeed = sqrt(BoostConfig.gravityMagnitude / radius) * 0.5
            
            // 5) Smoothly define a speed‐boost factor based on angle
            //
            //    Example:  f(angle) = 1 + (maxBoost - 1)*((cos(angle)+1)/2)
            //
            //    This yields:
            //      angle=0 (behind user)   => cos(0)=1  => raw=1.0 => boost= max
            //      angle=±π (front user)   => cos(±π)=-1 => raw=0.0 => boost= 1 (none)
            //      angle=±π/2 (left/right) => cos(±π/2)=0 => raw=0.5 => midrange
            //
            let rawFactor  = (cos(angle) + 1) * 0.5  // in [0..1]
            var boostFactor = 1 + (
                BoostConfig.maxBoostMultiplier - 1
            ) * rawFactor
            
            // 6) Final velocity
            let targetVelocity = orbitDirection * (baseOrbitSpeed * boostFactor)

            // Ensure at least some minimal speed-up in front
            boostFactor = max(boostFactor, 1.5)
            
            // 7) Smoothly lerp from current to target so it doesn’t jerk
            motion.linearVelocity = simd_mix(
                motion.linearVelocity,
                targetVelocity,
                SIMD3<Float>(repeating: dt * BoostConfig.lerpSharpness)
            )
            
            entity.components.set(motion)
        }
    }
}
