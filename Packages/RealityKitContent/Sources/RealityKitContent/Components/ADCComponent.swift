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
    
    // MARK: - Path and Distance Tracking
    /// Length of the current movement path
    public var pathLength: Float = 0
    
    /// Previously calculated path length
    public var previousPathLength: Float = 0
    
    /// Distance traveled along the current path
    public var traveledDistance: Float = 0
    
    // MARK: - Target Interpolation
    /// Previous target position for interpolation
    public var previousTargetPosition: SIMD3<Float>? = nil
    
    /// New target position for interpolation
    public var newTargetPosition: SIMD3<Float>? = nil
    
    /// Progress of target position interpolation (0 to 1)
    public var targetInterpolationProgress: Float = 0
    
    /// Duration for target interpolation
    public static let targetInterpolationDuration: Double = 1.0
    
    // MARK: - Path Tangent and Retargeting
    /// Previous path tangent
    public var previousPathTangent: SIMD3<Float>?  // Needs to be public
    
    /// Flag indicating if the current path is a retargeted path
    public var isRetargetedPath: Bool = false
    
    /// Composite progress of the current path
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
        case pathLength
        case previousPathLength
        case traveledDistance
        case previousTargetPosition
        case newTargetPosition
        case targetInterpolationProgress
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        state = try container.decode(State.self, forKey: .state)
        movementProgress = try container.decode(Float.self, forKey: .movementProgress)
        currentVelocity = try container.decodeIfPresent(SIMD3<Float>.self, forKey: .currentVelocity)
        speed = try container.decode(Float.self, forKey: .speed)
        proteinSpinSpeed = try container.decode(Float.self, forKey: .proteinSpinSpeed)
        targetCellID = try container.decodeIfPresent(Int.self, forKey: .targetCellID)
        targetEntityID = try container.decodeIfPresent(UInt64.self, forKey: .targetEntityID)
        startWorldPosition = try container.decodeIfPresent(SIMD3<Float>.self, forKey: .startWorldPosition)
        targetWorldPosition = try container.decodeIfPresent(SIMD3<Float>.self, forKey: .targetWorldPosition)
        needsRetarget = try container.decode(Bool.self, forKey: .needsRetarget)
        speedFactor = try container.decodeIfPresent(Float.self, forKey: .speedFactor)
        arcHeightFactor = try container.decodeIfPresent(Float.self, forKey: .arcHeightFactor)
        seekingDirection = try container.decodeIfPresent(SIMD3<Float>.self, forKey: .seekingDirection)
        seekingStartTime = try container.decodeIfPresent(Double.self, forKey: .seekingStartTime)
        previousPathTangent = try container.decodeIfPresent(SIMD3<Float>.self, forKey: .previousPathTangent)
        isRetargetedPath = try container.decode(Bool.self, forKey: .isRetargetedPath)
        compositeProgress = try container.decode(Float.self, forKey: .compositeProgress)
        pathLength = try container.decode(Float.self, forKey: .pathLength)
        previousPathLength = try container.decode(Float.self, forKey: .previousPathLength)
        traveledDistance = try container.decode(Float.self, forKey: .traveledDistance)
        previousTargetPosition = try container.decodeIfPresent(SIMD3<Float>.self, forKey: .previousTargetPosition)
        newTargetPosition = try container.decodeIfPresent(SIMD3<Float>.self, forKey: .newTargetPosition)
        targetInterpolationProgress = try container.decode(Float.self, forKey: .targetInterpolationProgress)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(state, forKey: .state)
        try container.encode(movementProgress, forKey: .movementProgress)
        try container.encodeIfPresent(currentVelocity, forKey: .currentVelocity)
        try container.encode(speed, forKey: .speed)
        try container.encode(proteinSpinSpeed, forKey: .proteinSpinSpeed)
        try container.encodeIfPresent(targetCellID, forKey: .targetCellID)
        try container.encodeIfPresent(targetEntityID, forKey: .targetEntityID)
        try container.encodeIfPresent(startWorldPosition, forKey: .startWorldPosition)
        try container.encodeIfPresent(targetWorldPosition, forKey: .targetWorldPosition)
        try container.encode(needsRetarget, forKey: .needsRetarget)
        try container.encodeIfPresent(speedFactor, forKey: .speedFactor)
        try container.encodeIfPresent(arcHeightFactor, forKey: .arcHeightFactor)
        try container.encodeIfPresent(seekingDirection, forKey: .seekingDirection)
        try container.encodeIfPresent(seekingStartTime, forKey: .seekingStartTime)
        try container.encodeIfPresent(previousPathTangent, forKey: .previousPathTangent)
        try container.encode(isRetargetedPath, forKey: .isRetargetedPath)
        try container.encode(compositeProgress, forKey: .compositeProgress)
        try container.encode(pathLength, forKey: .pathLength)
        try container.encode(previousPathLength, forKey: .previousPathLength)
        try container.encode(traveledDistance, forKey: .traveledDistance)
        try container.encodeIfPresent(previousTargetPosition, forKey: .previousTargetPosition)
        try container.encodeIfPresent(newTargetPosition, forKey: .newTargetPosition)
        try container.encode(targetInterpolationProgress, forKey: .targetInterpolationProgress)
    }
}
