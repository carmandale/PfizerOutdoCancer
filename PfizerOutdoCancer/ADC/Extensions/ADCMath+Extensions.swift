//import Foundation
import RealityKit

extension SIMD3 where Scalar == Float {
    func distance(from other: SIMD3<Float>) -> Float {
        return simd_distance(self, other)
    }

    var printed: String {
        String(format: "(%.8f, %.8f, %.8f)", x, y, z)
    }

    var adcNormalized: SIMD3 {
        return self / simd_length(self)
    }
    
    static let x: Self = .init(1, 0, 0)
    static let up: Self = .init(0, 1, 0)
    static let z: Self = .init(0, 0, 1)

    static func magnitude(pointA: SIMD3<Float>, pointB: SIMD3<Float>) -> Float {
        return pointA.distance(from: pointB)
    }
    
    
    func normalize(to other: SIMD3<Float>) -> SIMD3<Float> {
        // Calculate the vector between the two points
        let directionVector = other - self
        
        // Change from:
        // let magnitude = length(directionVector)
        
        // To:
        let magnitude = simd_length(directionVector)

        // Avoid division by zero
        guard magnitude != 0 else {
            return .zero // No unit vector exists if the two points are the same
        }
        
        // Normalize the vector
        return directionVector / magnitude
    }

    
    func findCollinearPoint(to other: SIMD3<Float>, distance: Float) -> SIMD3<Float> {
        print("ITR..✅ findCollinearPoint(): PointA: \(self), PointB: \(other), distance: \(distance)")
        // Calculate the vector between the two points
        let directionVector = other - self
        
        // Compute the magnitude of the vector
        let magnitude = simd_length(directionVector)
        
        // Avoid division by zero
        guard magnitude != 0 else {
            return self // Return the same point if both points are identical
        }
        
        // Normalize the direction vector
        let unitVector = directionVector / magnitude
        
        // Scale the unit vector by the specified distance
        let scaledVector = unitVector * distance
        
        // Add the scaled vector to the original point to find the new point
        return self + scaledVector
    }

}
