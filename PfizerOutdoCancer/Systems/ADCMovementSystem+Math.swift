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

    // 2. Add quadratic Bézier implementation
    static func quadraticBezierPoint(_ p0: SIMD3<Float>,
                                   _ p1: SIMD3<Float>,
                                   _ p2: SIMD3<Float>,
                                   t: Float) -> SIMD3<Float> {
        let mt = 1 - t
        return mt*mt * p0 + 2*mt*t * p1 + t*t * p2
    }


    /// Cubic Bézier point calculation (4 control points)
    static func bezierPoint(_ p0: SIMD3<Float>, 
                          _ p1: SIMD3<Float>, 
                          _ p2: SIMD3<Float>, 
                          _ p3: SIMD3<Float>, 
                          t: Float) -> SIMD3<Float> {
        let t2 = t * t
        let t3 = t2 * t
        let mt = 1 - t
        let mt2 = mt * mt
        let mt3 = mt2 * mt
        
        return mt3 * p0 + 
               3 * mt2 * t * p1 + 
               3 * mt * t2 * p2 + 
               t3 * p3
    }

    /// Calculates complete path metrics for movement initialization
    static func calculatePathMetrics(
        start: SIMD3<Float>,
        control: SIMD3<Float>,
        end: SIMD3<Float>
    ) -> (length: Float, initialDirection: SIMD3<Float>, controlPoint: SIMD3<Float>) {
        let pathLength = quadraticBezierLength(start, control, end)
        let initialDerivative = 2 * (control - start)
        let initialDirection = normalize(initialDerivative)
        return (pathLength, initialDirection, control)
    }

    /// Validates and clamps progress value with safety checks
    static func validatedProgress(_ component: ADCComponent) -> Float {
        guard component.pathLength > Float.ulpOfOne else { return 1.0 }
        let raw = component.traveledDistance / component.pathLength
        return simd_clamp(raw, 0, 1)
    }
    
    /// Calculates quadratic Bézier curve length using 5th-order Gauss-Legendre quadrature
    /// - Returns: Accurate arc length in meters
    static func quadraticBezierLength(_ p0: SIMD3<Float>, 
                                    _ p1: SIMD3<Float>, 
                                    _ p2: SIMD3<Float>) -> Float {
        // Precisely tuned Gauss-Legendre coefficients for t ∈ [0,1]
        let weights: [Float] = [0.236926885056189, 0.478628670499366, 
                               0.568888888888889, 0.478628670499366, 
                               0.236926885056189]
        let nodes: [Float] = [0.046910077030668, 0.230765344947158, 
                            0.5, 0.769234655052842, 0.953089922969332]
        
        return nodes.enumerated().reduce(0) { acc, pair in
            let t = pair.element
            // Bézier derivative: B'(t) = 2(1-t)(P1-P0) + 2t(P2-P1)
            let derivative = 2 * ((1 - t) * (p1 - p0) + t * (p2 - p1))
            return acc + weights[pair.offset] * simd_length(derivative)
        } * 0.5 // Scale from [-1,1] integration range to [0,1]
    }

    /// Legacy implementation for validation/debugging
//    @available(*, deprecated, renamed: "quadraticBezierLength", 
//        message: "Use optimized quadrature method for runtime calculations")
//    static func debugStepBasedBezierLength(_ p0: SIMD3<Float>, 
//                                         _ p1: SIMD3<Float>, 
//                                         _ p2: SIMD3<Float>, 
//                                         steps: Int = 20) -> Float {
//        guard steps > 0 else { return 0 }
//        
//        return (1...steps).reduce((length: Float(0), prev: p0)) { acc, step in
//            let t = Float(step)/Float(steps)
//            let current = bezierPoint(p0, p1, p2, t: t)
//            let segmentLength = simd_distance(current, acc.prev)
//            return (acc.length + segmentLength, current)
//        }.length
//    }
    
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
