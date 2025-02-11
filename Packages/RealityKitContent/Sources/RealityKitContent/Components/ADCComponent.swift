/*
 See LICENSE.txt file for this sample's licensing information.

 Abstract:
 Component that tracks ADC (Antibody-Drug Conjugate) state and movement parameters.
*/

import RealityKit
import Foundation

/// Component that defines ADC behavior and movement parameters.
public struct ADCComponent: Component, Codable {
    
    // MARK: - State
    
    /// Represents the various states of an ADC.
    public enum State: String, Codable {
        case idle       // Waiting for a target.
        case moving     // Currently moving toward a target.
        case seeking    // Moving without a target, looking for one.
        case retargeting// Transitioning to a new target.
        case attached   // Attached to a cancer cell.
        case orbiting   // NEW: Orbiting the user/headTrackingRoot
    }
    
    /// The current state of the ADC.
    public var state: State = .idle

    // MARK: - Movement (Distance-Based)
    
    /// The total length (arc-length) of the current movement path.
    public var pathLength: Float = 0
    
    /// The distance traveled along the current path.
    public var traveledDistance: Float = 0
    
    /// A computed property that returns normalized progress (0 to 1) along the path.
    public var normalizedProgress: Float {
        return pathLength > 0 ? traveledDistance / pathLength : 0
    }
    
    /// The current velocity of the ADC.
    public var currentVelocity: SIMD3<Float>? = nil
    
    /// The base speed of movement.
    public var speed: Float = 2.0

    // MARK: - Rotation and Animation
    
    /// Speed of the protein spin animation (typically randomized per instance).
    public var proteinSpinSpeed: Float = 0.0

    // MARK: - Target Information
    
    /// The target cancer cell ID.
    public var targetCellID: Int? = nil
    
    /// The ID of the target entity.
    public var targetEntityID: UInt64? = nil
    
    /// The starting position (in world space) when movement begins.
    public var startWorldPosition: SIMD3<Float>? = nil
    
    /// The target position (in world space) for movement.
    public var targetWorldPosition: SIMD3<Float>? = nil
    
    /// A flag indicating whether retargeting is needed.
    public var needsRetarget: Bool = false

    // MARK: - Randomization Factors
    
    /// A speed factor (random value within a defined range) applied to movement.
    public var speedFactor: Float? = nil
    
    /// An arc height factor (random value within a defined range) for the curved path.
    public var arcHeightFactor: Float? = nil

    // MARK: - Seeking Parameters
    
    /// The initial direction for seeking movement.
    public var seekingDirection: SIMD3<Float>? = nil
    
    /// The timestamp when seeking began (used to enforce a minimum duration).
    public var seekingStartTime: Double? = nil
    
    /// The minimum duration (in seconds) that an ADC must seek before locking onto a target.
    public static let minimumSeekingDuration: Double = 2.0

    // MARK: - Path Tracking and Arc-Length Parameterization
    
    /// A lookup table storing cumulative arc lengths (sampled along the quadratic Bézier curve).
    /// This is used to remap a traveled distance into a parameter t (0 to 1).
    public var lookupTable: [Float]? = nil

    // MARK: - Target Interpolation (for Retargeting)
    
    /// The previous target position used for interpolating when a retarget occurs.
    public var previousTargetPosition: SIMD3<Float>? = nil
    
    /// The new target position (after retargeting) for interpolation.
    public var newTargetPosition: SIMD3<Float>? = nil
    
    /// The progress (0 to 1) of the target position interpolation.
    public var targetInterpolationProgress: Float = 0
    
    /// The duration (in seconds) for target interpolation.
    public static let targetInterpolationDuration: Double = 1.0

    // MARK: - Additional Retargeting and Path Data
    
    /// The previously calculated path length (used during retargeting adjustments).
    public var previousPathLength: Float = 0
    
    /// The previous path tangent (optional; useful for composite path calculations).
    public var previousPathTangent: SIMD3<Float>? = nil
    
    /// A flag indicating if the current path is a retargeted path.
    public var isRetargetedPath: Bool = false
    
    /// A flag indicating if this ADC has been retargeted.
    public var wasRetargeted: Bool = false
    
    /// A flag indicating if this ADC has collided with its target cell.
    public var hasCollided: Bool = false
    
    /// The composite progress of the current path (if using a composite curve).
    public var compositeProgress: Float = 0

    // MARK: - Orbiting Parameters
    
    /// The radius of the orbit.
    public var orbitRadius: Float = 3.0
    
    /// The base height of the orbit.
    public var orbitHeight: Float = 1.0
    
    /// The speed of the orbit.
    public var orbitSpeed: Float = 0.5
    
    /// The current angle in the orbit.
    public var orbitTheta: Float = 0.0
    
    /// The tumble angle of the orbit.
    public var tumbleAngle: Float = 0.0
    
    /// The tumble speed of the orbit.
    public var tumbleSpeed: Float = 0.0
    
    // MARK: - Organic Orbiting Parameters (NEW)
    
    /// The amplitude of vertical oscillation for organic orbiting.
    public var verticalOscillationAmplitude: Float = 0.0
    
    /// The frequency of vertical oscillation.
    public var verticalOscillationFrequency: Float = 1.0
    
    /// The phase offset for vertical oscillation.
    public var verticalOscillationPhase: Float = 0.0
    
    // MARK: - Orbiting Transition Parameters (NEW)
    
    /// The starting position for the orbit transition.
    public var orbitTransitionStartPosition: SIMD3<Float> = [0, 0, 0]
    
    /// The progress (0 to 1) of the orbit transition.
    /// (When less than 1, the ADC is still transitioning smoothly to orbiting.)
    public var orbitTransitionProgress: Float = 1.0
    
    /// The duration (in seconds) of the orbit transition.
    public var orbitTransitionDuration: Float = 1.0

    // MARK: - Initialization
    
    /// Default initializer.
    public init() { }
    
    /// Initializes the ADCComponent with the given parameters.
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
        // Movement
        case currentVelocity, speed
        // Rotation and Animation
        case proteinSpinSpeed
        // Target Information
        case targetCellID, targetEntityID, startWorldPosition, targetWorldPosition, needsRetarget
        // Randomization Factors
        case speedFactor, arcHeightFactor
        // Seeking Parameters
        case seekingDirection, seekingStartTime
        // Path Tracking and Arc-Length Parameterization
        case pathLength, traveledDistance, lookupTable
        // Target Interpolation (for Retargeting)
        case previousTargetPosition, newTargetPosition, targetInterpolationProgress
        // Additional Retargeting and Path Data
        case previousPathLength, previousPathTangent, isRetargetedPath, wasRetargeted, hasCollided, compositeProgress
        // Orbiting Parameters
        case orbitRadius, orbitHeight, orbitSpeed, orbitTheta, tumbleAngle, tumbleSpeed
        // Organic Orbiting Parameters (NEW)
        case verticalOscillationAmplitude, verticalOscillationFrequency, verticalOscillationPhase
        // Orbiting Transition Parameters (NEW)
        case orbitTransitionStartPosition, orbitTransitionProgress, orbitTransitionDuration
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        state = try container.decode(State.self, forKey: .state)
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
        pathLength = try container.decode(Float.self, forKey: .pathLength)
        traveledDistance = try container.decode(Float.self, forKey: .traveledDistance)
        lookupTable = try container.decodeIfPresent([Float].self, forKey: .lookupTable)
        previousTargetPosition = try container.decodeIfPresent(SIMD3<Float>.self, forKey: .previousTargetPosition)
        newTargetPosition = try container.decodeIfPresent(SIMD3<Float>.self, forKey: .newTargetPosition)
        targetInterpolationProgress = try container.decode(Float.self, forKey: .targetInterpolationProgress)
        previousPathLength = try container.decode(Float.self, forKey: .previousPathLength)
        previousPathTangent = try container.decodeIfPresent(SIMD3<Float>.self, forKey: .previousPathTangent)
        isRetargetedPath = try container.decode(Bool.self, forKey: .isRetargetedPath)
        wasRetargeted = try container.decode(Bool.self, forKey: .wasRetargeted)
        hasCollided = try container.decode(Bool.self, forKey: .hasCollided)
        compositeProgress = try container.decode(Float.self, forKey: .compositeProgress)
        orbitRadius = try container.decode(Float.self, forKey: .orbitRadius)
        orbitHeight = try container.decodeIfPresent(Float.self, forKey: .orbitHeight) ?? 1.0
        orbitSpeed = try container.decode(Float.self, forKey: .orbitSpeed)
        orbitTheta = try container.decode(Float.self, forKey: .orbitTheta)
        tumbleAngle = try container.decodeIfPresent(Float.self, forKey: .tumbleAngle) ?? 0.0
        tumbleSpeed = try container.decodeIfPresent(Float.self, forKey: .tumbleSpeed) ?? 0.0
        verticalOscillationAmplitude = try container.decodeIfPresent(Float.self, forKey: .verticalOscillationAmplitude) ?? 0.0
        verticalOscillationFrequency = try container.decodeIfPresent(Float.self, forKey: .verticalOscillationFrequency) ?? 1.0
        verticalOscillationPhase = try container.decodeIfPresent(Float.self, forKey: .verticalOscillationPhase) ?? 0.0
        orbitTransitionStartPosition = try container.decodeIfPresent(SIMD3<Float>.self, forKey: .orbitTransitionStartPosition) ?? [0, 0, 0]
        orbitTransitionProgress = try container.decodeIfPresent(Float.self, forKey: .orbitTransitionProgress) ?? 1.0
        orbitTransitionDuration = try container.decodeIfPresent(Float.self, forKey: .orbitTransitionDuration) ?? 1.0
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(state, forKey: .state)
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
        try container.encode(pathLength, forKey: .pathLength)
        try container.encode(traveledDistance, forKey: .traveledDistance)
        try container.encodeIfPresent(lookupTable, forKey: .lookupTable)
        try container.encodeIfPresent(previousTargetPosition, forKey: .previousTargetPosition)
        try container.encodeIfPresent(newTargetPosition, forKey: .newTargetPosition)
        try container.encode(targetInterpolationProgress, forKey: .targetInterpolationProgress)
        try container.encode(previousPathLength, forKey: .previousPathLength)
        try container.encodeIfPresent(previousPathTangent, forKey: .previousPathTangent)
        try container.encode(isRetargetedPath, forKey: .isRetargetedPath)
        try container.encode(wasRetargeted, forKey: .wasRetargeted)
        try container.encode(hasCollided, forKey: .hasCollided)
        try container.encode(compositeProgress, forKey: .compositeProgress)
        try container.encode(orbitRadius, forKey: .orbitRadius)
        try container.encodeIfPresent(orbitHeight, forKey: .orbitHeight)
        try container.encode(orbitSpeed, forKey: .orbitSpeed)
        try container.encode(orbitTheta, forKey: .orbitTheta)
        try container.encode(tumbleAngle, forKey: .tumbleAngle)
        try container.encode(tumbleSpeed, forKey: .tumbleSpeed)
        try container.encode(verticalOscillationAmplitude, forKey: .verticalOscillationAmplitude)
        try container.encode(verticalOscillationFrequency, forKey: .verticalOscillationFrequency)
        try container.encode(verticalOscillationPhase, forKey: .verticalOscillationPhase)
        try container.encode(orbitTransitionStartPosition, forKey: .orbitTransitionStartPosition)
        try container.encode(orbitTransitionProgress, forKey: .orbitTransitionProgress)
        try container.encode(orbitTransitionDuration, forKey: .orbitTransitionDuration)
    }
}