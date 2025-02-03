// ADCMovementSystem+Math.swift

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
    
    /// Quadratic Bézier point calculation: B(t) = (1-t)²P₀ + 2(1-t)tP₁ + t²P₂
    static func quadraticBezierPoint(_ p0: SIMD3<Float>,
                                     _ p1: SIMD3<Float>,
                                     _ p2: SIMD3<Float>,
                                     t: Float) -> SIMD3<Float> {
        let mt = 1 - t
        return mt * mt * p0 + 2 * mt * t * p1 + t * t * p2
    }
    
    /// Given a quadratic Bézier curve, sample it to build a lookup table of cumulative arc lengths.
    static func buildLookupTableForQuadraticBezier(start: SIMD3<Float>, control: SIMD3<Float>, end: SIMD3<Float>, samples: Int) -> [Float] {
        var lookup: [Float] = [0.0]
        var previousPoint = start
        for i in 1...samples {
            let t = Float(i) / Float(samples)
            let point = quadraticBezierPoint(start, control, end, t: t)
            let segmentLength = simd_distance(point, previousPoint)
            let cumulative = lookup.last! + segmentLength
            lookup.append(cumulative)
            previousPoint = point
        }
        return lookup
    }
    
    /// Given the traveled distance and a lookup table, interpolate the corresponding parameter t.
    static func lookupParameter(forDistance distance: Float, lookup: [Float]) -> Float {
        guard let totalLength = lookup.last, totalLength > 0 else { return 0 }
        let d = simd_clamp(distance, 0, totalLength)
        for i in 1..<lookup.count {
            if lookup[i] >= d {
                let t0 = Float(i - 1) / Float(lookup.count - 1)
                let t1 = Float(i) / Float(lookup.count - 1)
                let d0 = lookup[i - 1]
                let d1 = lookup[i]
                let segmentFraction = (d - d0) / (d1 - d0)
                return t0 + segmentFraction * (t1 - t0)
            }
        }
        return 1.0
    }
    
    /// Calculates complete path metrics (for legacy or debugging purposes).
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
    
    /// Quadratic Bézier curve length using Gauss–Legendre quadrature.
    static func quadraticBezierLength(_ p0: SIMD3<Float>, _ p1: SIMD3<Float>, _ p2: SIMD3<Float>) -> Float {
        let weights: [Float] = [0.236926885056189, 0.478628670499366, 0.568888888888889, 0.478628670499366, 0.236926885056189]
        let nodes: [Float] = [0.046910077030668, 0.230765344947158, 0.5, 0.769234655052842, 0.953089922969332]
        
        return nodes.enumerated().reduce(0) { acc, pair in
            let t = pair.element
            let derivative = 2 * ((1 - t) * (p1 - p0) + t * (p2 - p1))
            return acc + weights[pair.offset] * simd_length(derivative)
        } * 0.5
    }
    
    internal static func validateQuaternion(_ quat: simd_quatf) -> Bool {
        if quat.vector.x.isNaN || quat.vector.y.isNaN || quat.vector.z.isNaN || quat.vector.w.isNaN {
            return false
        }
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
        if let proteinComplex = entity.findEntity(named: "antibodyProtein_complex"),
           let adcComponent = entity.components[ADCComponent.self] {
            let worldSpinAxis = currentOrientation.act([-1, 0, 0])
            let spinRotation = simd_quatf(angle: Float(deltaTime) * adcComponent.proteinSpinSpeed, axis: worldSpinAxis)
            proteinComplex.orientation = spinRotation * proteinComplex.orientation
        }
        return currentOrientation
    }
}