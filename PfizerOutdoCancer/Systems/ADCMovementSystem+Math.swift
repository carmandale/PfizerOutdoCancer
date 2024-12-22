import RealityKit
import Foundation

@MainActor
extension ADCMovementSystem {
    internal static func mix(_ a: Float, _ b: Float, t: Float) -> Float {
        return a * (1 - t) + b * t
    }
    
    internal static func mix(_ a: SIMD3<Float>, _ b: SIMD3<Float>, t: Float) -> SIMD3<Float> {
        return a * (1 - t) + b * t
    }
    
    internal static func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
        let t = max(0, min((x - edge0) / (edge1 - edge0), 1))
        return t * t * (3 - 2 * t)
    }
    
    internal static func validateQuaternion(_ quat: simd_quatf) -> Bool {
        // Check if any component is NaN
        if quat.vector.x.isNaN || quat.vector.y.isNaN || quat.vector.z.isNaN || quat.vector.w.isNaN {
            return false
        }
        // Check if quaternion is normalized (length ≈ 1)
        let length = sqrt(quat.vector.x * quat.vector.x + 
                        quat.vector.y * quat.vector.y + 
                        quat.vector.z * quat.vector.z + 
                        quat.vector.w * quat.vector.w)
        return abs(length - 1.0) < 0.001
    }
    
    static func calculateOrientation(progress: Float,
                                  direction: SIMD3<Float>,
                                  deltaTime: TimeInterval,
                                  currentOrientation: simd_quatf,
                                  entity: Entity) -> simd_quatf {
        // Set root to face movement direction
        let baseOrientation = simd_quatf(from: [0, 0, 1], to: direction)
        
        // Update protein complex spin in world space
        if let proteinComplex = entity.findEntity(named: "antibodyProtein_complex") {
            // Convert local X-axis to world space
            let worldSpinAxis = baseOrientation.act([-1, 0, 0])
            let spinRotation = simd_quatf(angle: Float(deltaTime) * proteinSpinSpeed, axis: worldSpinAxis)
            
            // Apply spin in world space
            proteinComplex.orientation = spinRotation * proteinComplex.orientation
        }
        
        return baseOrientation
    }
}
