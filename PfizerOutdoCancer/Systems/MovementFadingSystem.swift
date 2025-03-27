import Foundation
import RealityKit
import ARKit

/// System that handles movement-based fading of entities in a RealityKit scene
@MainActor
public class MovementFadingSystem: System {
    // Query for entities with the fading component
    static let query = EntityQuery(where: .has(MovementFadingComponent.self))
    
    // Reference to the app model for accessing tracking data
    private static var sharedAppModel: AppModel?
    
    // Movement tracking state
    private var previousPosition: SIMD3<Float>?
    private var previousTime: TimeInterval = 0
    private var velocitySmoothed: Float = 0.0
    
    // Smoothing factor for velocity (0-1, higher = less smoothing)
    private let velocitySmoothingFactor: Float = 0.3
    
    // Adaptive frame skipping for performance optimization
    private var frameCounter: Int = 0
    private var adaptiveFrameSkip: Int = 6  // Start with 15Hz at 90fps
    private var lastSignificantMovement: TimeInterval = 0
    
    // Batch processing for opacity changes
    private var pendingOpacityChanges: [(Entity, Float)] = []
    
    /// Sets the app model reference to access tracking data
    /// - Parameter appModel: The application model that contains tracking providers
    internal static func setAppModel(_ appModel: AppModel) {
        sharedAppModel = appModel
    }
    
    /// Required initializer for RealityKit systems
    /// - Parameter scene: The scene this system is added to
    public required init(scene: RealityKit.Scene) {
        previousTime = Date().timeIntervalSinceReferenceDate
        lastSignificantMovement = previousTime
        Logger.debug("🎭 MovementFadingSystem: Initialized")
    }
    
    /// Called each frame to update entity opacity based on movement
    /// - Parameter context: The scene update context providing frame timing and entity access
    public func update(context: SceneUpdateContext) {
        // Adaptive performance optimization: only process at reduced frequency
        frameCounter += 1
        if frameCounter < adaptiveFrameSkip {
            return
        }
        frameCounter = 0
        
        // Get current time using RealityKit pattern
        let currentTime = Date().timeIntervalSinceReferenceDate
        
        // Get device tracking data
        guard let appModel = Self.sharedAppModel,
              case .running = appModel.trackingManager.worldTrackingProvider.state,
              let deviceAnchor = appModel.trackingManager.worldTrackingProvider.queryDeviceAnchor(atTimestamp: currentTime) else {
            return
        }
        
        let devicePosition = deviceAnchor.originFromAnchorTransform.translation()
        let deltaTime = Float(currentTime - previousTime)
        
        // Skip tiny time increments to avoid division issues
        guard deltaTime > 0.001 else {
            return
        }
        
        // Calculate instantaneous velocity
        var instantVelocity: Float = 0.0
        if let prevPos = previousPosition {
            let distanceSq = simd_distance_squared(devicePosition, prevPos)
            instantVelocity = sqrt(distanceSq) / deltaTime
        }
        
        // Apply exponential smoothing to velocity for more natural detection
        velocitySmoothed = ADCMovementSystem.mix(velocitySmoothed, instantVelocity, t: velocitySmoothingFactor)
        
        // Optimize frame skip rate based on movement
        updateAdaptiveFrameSkip(currentTime: currentTime)
        
        // Early exit if velocity is well below threshold
        if velocitySmoothed < 0.02 {  // Hard minimum
            previousPosition = devicePosition
            previousTime = currentTime
            return  // Skip entity processing entirely
        }
        
        // Clear previous batch
        pendingOpacityChanges.removeAll()
        
        // Process each entity with the fading component - FIX: Added updatingSystemWhen parameter
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            processEntity(entity, devicePosition: devicePosition)
        }
        
        // Apply batched opacity changes
        if !pendingOpacityChanges.isEmpty {
            Task { @MainActor in
                for (entity, opacity) in pendingOpacityChanges {
                    var fadingComponent = entity.components[MovementFadingComponent.self]!
                    fadingComponent.currentOpacity = opacity
                    entity.components[MovementFadingComponent.self] = fadingComponent
                    
                    await entity.fadeOpacity(to: opacity, 
                                     duration: fadingComponent.transitionDuration,
                                     timing: .easeInOut)
                }
            }
        }
        
        previousPosition = devicePosition
        previousTime = currentTime
    }
    
    /// Updates the adaptive frame skip rate based on recent movement
    private func updateAdaptiveFrameSkip(currentTime: TimeInterval) {
        let timeSinceMovement = currentTime - lastSignificantMovement
        
        // Reduce frequency when idle
        if velocitySmoothed < 0.05 {
            if timeSinceMovement > 1.0 {
                adaptiveFrameSkip = min(18, adaptiveFrameSkip + 1)  // Up to ~5Hz when idle
            }
        } else {
            adaptiveFrameSkip = 6  // Back to 15Hz when moving
            lastSignificantMovement = currentTime
        }
    }
    
    /// Processes a single entity for movement fading
    /// - Parameters:
    ///   - entity: The entity to process
    ///   - devicePosition: Current device position in world space
    private func processEntity(_ entity: Entity, devicePosition: SIMD3<Float>) {
        guard var fadingComponent = entity.components[MovementFadingComponent.self] else { return }
        
        // Initialize if needed
        if !fadingComponent.initialized {
            fadingComponent.origin = devicePosition
            fadingComponent.initialized = true
            entity.components[MovementFadingComponent.self] = fadingComponent
            return
        }
        
        // Determine movement state with hysteresis for stability
        let wasMoving = fadingComponent.isMoving
        if fadingComponent.isMoving {
            // Require lower velocity to stop (prevents flickering)
            fadingComponent.isMoving = velocitySmoothed > (fadingComponent.velocityThreshold * 0.8)
        } else {
            // Require higher velocity to start (prevents accidental triggers)
            fadingComponent.isMoving = velocitySmoothed > fadingComponent.velocityThreshold
        }
        
        // Handle origin reset when stopping
        if wasMoving && !fadingComponent.isMoving {
            fadingComponent.origin = devicePosition
            entity.components[MovementFadingComponent.self] = fadingComponent
        }
        
        // Performance optimization: Use squared distances for faster comparisons
        let distanceSquared = simd_distance_squared(devicePosition, fadingComponent.origin)
        let startRadiusSquared = fadingComponent.fadeRadiusStart * fadingComponent.fadeRadiusStart
        
        // Early exit if entity hasn't moved past start threshold
        if !fadingComponent.isMoving || distanceSquared <= startRadiusSquared {
            // Only restore opacity if needed
            if fadingComponent.currentOpacity < fadingComponent.maxOpacity {
                pendingOpacityChanges.append((entity, fadingComponent.maxOpacity))
            }
            return
        }
        
        // Only compute target opacity if movement state and distance warrant it
        let endRadiusSquared = fadingComponent.fadeRadiusEnd * fadingComponent.fadeRadiusEnd
        
        // Calculate target opacity with smooth transition
        var targetOpacity: Float
        
        if distanceSquared >= endRadiusSquared {
            targetOpacity = fadingComponent.minOpacity
        } else {
            // Need sqrt for accurate interpolation
            let distance = sqrt(distanceSquared)
            
            // Use existing smoothstep function from ADCMovementSystem
            let t = ADCMovementSystem.smoothstep(
                fadingComponent.fadeRadiusStart,
                fadingComponent.fadeRadiusEnd,
                distance
            )
            // Use existing mix function from ADCMovementSystem
            targetOpacity = ADCMovementSystem.mix(fadingComponent.maxOpacity, fadingComponent.minOpacity, t: t)
        }
        
        // Only update if opacity would change significantly
        if abs(targetOpacity - fadingComponent.currentOpacity) > 0.01 {
            pendingOpacityChanges.append((entity, targetOpacity))
        }
    }
} 