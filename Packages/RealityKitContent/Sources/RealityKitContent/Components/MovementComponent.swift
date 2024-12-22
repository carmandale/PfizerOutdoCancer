import RealityKit
import Foundation

/// A component that defines movement parameters for an entity
@MainActor
public struct MovementComponent: Component, Codable {
    /// The duration of the movement effect
    public var time: Double = 0
    
    /// The speed at which the entity moves over time
    public var speed: Double = 1.0
    
    /// The axis that the object rotates around
    // public var axis: SIMD3<Float> = SIMD3<Float>(0, 1, 0)
    
    /// Initialize the movement component with default values
    public init() {}
    
    /// Initialize the movement component with specified parameters
    /// - Parameters:
    ///   - speed: Speed of movement over time
    ///   - axis: Axis of rotation as SIMD3<Float>
//     public init(speed: Double = 1.0, axis: SIMD3<Float> = SIMD3<Float>(0, 1, 0)) {
//         self.speed = speed
//         self.axis = axis
//     }
    
//     // Make sure we have proper coding keys
//     private enum CodingKeys: String, CodingKey {
//         case time
//         case speed
//         case axis
//     }
    
//     // Add proper encoding/decoding
//     nonisolated public init(from decoder: Decoder) throws {
//         let container = try decoder.container(keyedBy: CodingKeys.self)
//         time = try container.decode(Double.self, forKey: .time)
//         speed = try container.decode(Double.self, forKey: .speed)
//         axis = try container.decode(SIMD3<Float>.self, forKey: .axis)
//     }
    
//     nonisolated public func encode(to encoder: Encoder) throws {
//         var container = encoder.container(keyedBy: CodingKeys.self)
//         try container.encode(time, forKey: .time)
//         try container.encode(speed, forKey: .speed)
//         try container.encode(axis, forKey: .axis)
//     }
// }

// // MARK: - Entity Extension
// public extension Entity {
//     /// Property for getting or setting an entity's MovementComponent
//     var movementComponent: MovementComponent? {
//         get { components[MovementComponent.self] }
//         set { components[MovementComponent.self] = newValue }
//     }
}
// 