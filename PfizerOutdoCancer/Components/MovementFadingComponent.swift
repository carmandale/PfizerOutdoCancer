import Foundation
import RealityKit

/// Marks entities that should fade based on user movement
public struct MovementFadingComponent: Component, Codable {
    // Configuration
    /// Distance in meters when fading begins
    public var fadeRadiusStart: Float = 1.0
    
    /// Distance in meters when fully faded
    public var fadeRadiusEnd: Float = 2.0
    
    /// Minimum opacity value when fully faded
    public var minOpacity: Float = 0.0
    
    /// Maximum opacity value when not faded
    public var maxOpacity: Float = 1.0
    
    /// Threshold in meters/second to detect movement
    public var velocityThreshold: Float = 0.1
    
    /// Duration in seconds for opacity transitions
    public var transitionDuration: TimeInterval = 0.5
    
    // Internal state - not meant to be modified directly
    var origin: SIMD3<Float> = .zero
    var currentOpacity: Float = 1.0
    var isMoving: Bool = false
    var initialized: Bool = false
    
    /// Default initializer with standard configuration
    public init() {}
    
    /// Initializer with custom parameters
    public init(
        fadeRadiusStart: Float = 1.0,
        fadeRadiusEnd: Float = 2.0,
        minOpacity: Float = 0.0,
        maxOpacity: Float = 1.0,
        velocityThreshold: Float = 0.1,
        transitionDuration: TimeInterval = 0.5
    ) {
        self.fadeRadiusStart = fadeRadiusStart
        self.fadeRadiusEnd = fadeRadiusEnd
        self.minOpacity = minOpacity
        self.maxOpacity = maxOpacity
        self.velocityThreshold = velocityThreshold
        self.transitionDuration = transitionDuration
    }
} 