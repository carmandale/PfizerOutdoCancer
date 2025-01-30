/*
See LICENSE.txt file for this sample's licensing information.

Abstract:
Component that tracks ADC (Antibody-Drug Conjugate) state and movement parameters.
*/

import RealityKit
import Foundation

/// Component that defines ADC behavior and movement parameters
public struct ADCComponent: Component, Codable {
    /// Current state of the ADC
    public enum State: String, Codable {
        case idle       // Initial state, waiting for target
        case moving     // Moving towards target
        case seeking    // Moving without target, looking for one
        case retargeting // Found new target, transitioning
        case attached   // Attached to cancer cell
    }
    
    // MARK: - State
    /// Current state of the ADC
    public var state: State = .idle
    
    // MARK: - Movement
    /// Movement progress (0 to 1)
    public var movementProgress: Float = 0
    
    /// Current velocity
    public var currentVelocity: SIMD3<Float>? = nil
    
    /// Speed of movement
    public var speed: Float = 2.0
    
    // MARK: - Rotation
    /// Speed of protein spin animation (random per instance)
    public var proteinSpinSpeed: Float = 0.0
    
    // MARK: - Target Information
    /// Target cancer cell ID
    public var targetCellID: Int? = nil
    
    /// ID of the target entity
    public var targetEntityID: UInt64? = nil
    
    /// Starting position in world space
    public var startWorldPosition: SIMD3<Float>? = nil
    
    /// Target position in world space
    public var targetWorldPosition: SIMD3<Float>? = nil
    
    /// Flag indicating if retargeting is needed
    public var needsRetarget: Bool = false
    
    // MARK: - Movement Parameters
    /// Speed factor for movement (random value between speedRange)
    public var speedFactor: Float? = nil
    
    /// Arc height factor for movement (random value between arcHeightRange)
    public var arcHeightFactor: Float? = nil
    
    // MARK: - Seeking Parameters
    /// Initial direction for seeking movement
    public var seekingDirection: SIMD3<Float>? = nil
    
    /// When seeking started (used to enforce minimum seeking duration)
    public var seekingStartTime: Double? = nil
    
    /// Minimum duration (in seconds) that an ADC must seek before targeting
    public static let minimumSeekingDuration: Double = 2.0
    
    // Add these to the existing struct:
    public var previousPathTangent: SIMD3<Float>?  // Needs to be public
    public var isRetargetedPath: Bool = false
    public var compositeProgress: Float = 0
    
    // MARK: - Initialization
    /// Initialize ADC component and register system
    public init() {
    }
    
    /// Initialize ADC component with specified parameters
    public init(
        state: State = .idle,
        targetCellID: Int? = nil,
        targetEntityID: UInt64? = nil,
        seekingDirection: SIMD3<Float>? = nil
    ) {
        self.state = state
        self.targetCellID = targetCellID
        self.targetEntityID = targetEntityID
        self.seekingDirection = seekingDirection
    }
    
    // MARK: - Codable Implementation
    private enum CodingKeys: String, CodingKey {
        case state
        case movementProgress
        case currentVelocity
        case speed
        case proteinSpinSpeed
        case targetCellID
        case targetEntityID
        case startWorldPosition
        case targetWorldPosition
        case needsRetarget
        case speedFactor
        case arcHeightFactor
        case seekingDirection
        case seekingStartTime
        case previousPathTangent
        case isRetargetedPath
        case compositeProgress
    }
}
