import RealityKit
import Foundation
import RealityKitContent

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
    
    /// Calculates the approximate arc length of a quadratic Bezier curve
    /// Uses Legendre-Gauss quadrature for accurate approximation
    internal static func quadraticBezierLength(p0: SIMD3<Float>, p1: SIMD3<Float>, p2: SIMD3<Float>) -> Float {
        print("\n=== Bezier Length Calculation ===")
        print("🎯 P0: \(p0)")
        print("🎯 P1: \(p1)")
        print("🎯 P2: \(p2)")
        
        // Legendre-Gauss abscissae for n=5
        let t = [0.0469100770, 0.2307653449, 0.5, 0.7692346551, 0.9530899230]
        let w = [0.1184634425, 0.2393143352, 0.2844444444, 0.2393143352, 0.1184634425]
        
        var length: Float = 0
        
        // Calculate the derivative at each sample point and accumulate the length
        for i in 0..<5 {
            let tt = Float(t[i])
            // Derivative of quadratic Bezier: B'(t) = 2(1-t)(p1-p0) + 2t(p2-p1)
            let derivative = 2 * (1 - tt) * (p1 - p0) + 2 * tt * (p2 - p1)
            let derivativeLength = simd_length(derivative)
            print("📈 Sample \(i) - t: \(tt), derivative length: \(derivativeLength)")
            length += Float(w[i]) * derivativeLength
        }
        
        print("📏 Final Length: \(length)")
        return length
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
        // Update protein complex spin in world space
        if let proteinComplex = entity.findEntity(named: "antibodyProtein_complex"),
           let adcComponent = entity.components[ADCComponent.self] {
            // Convert local X-axis to world space
            let worldSpinAxis = currentOrientation.act([-1, 0, 0])
            let spinRotation = simd_quatf(angle: Float(deltaTime) * adcComponent.proteinSpinSpeed, axis: worldSpinAxis)
            
            // Apply spin in world space
            proteinComplex.orientation = spinRotation * proteinComplex.orientation
        }
        
        return currentOrientation
    }
}
