import RealityKit
import SwiftUI

@Observable
public class CancerCellParameters {
    public static let minRequiredHits = 4
    public static let maxRequiredHits = 8
    
    // Default impact scale for tutorial cells (constant to ensure thread safety)
    public static let tutorialImpactScale: Float = 0.00001
    
    public var cellID: Int? = nil
    public var hitCount: Int = 0
    public var isDestroyed: Bool = false
    public var isScaling: Bool = false
    public var targetScale: Float = 1.0
    public var currentScale: Float = 1.0
    public var wasJustHit: Bool = false
    public var isEmittingParticles: Bool = false
    public var requiredHits: Int
    public var physicsEnabled: Bool = true
    public var linearVelocity: SIMD3<Float> = .zero
    public var angularVelocity: SIMD3<Float> = .zero
    public var isTutorialCell: Bool = false
    public var impactScale: Float = 0.0001  // Default full impact
    public var testValue: Int = 23  // Added for debug purposes
    
    // Scale thresholds for different hit counts
    public static let scaleThresholds: [(hits: Int, scale: Float)] = [
        (1, 0.9),   // First hit
        (3, 0.8),   // Third hit
        (6, 0.7),   // Sixth hit
        (9, 0.6),   // Ninth hit
        (12, 0.5),  // Twelfth hit
        (15, 0.4)   // Fifteenth hit
    ]
    
    public init(cellID: Int? = nil) {
        self.cellID = cellID
        self.requiredHits = Int.random(in: Self.minRequiredHits...Self.maxRequiredHits)
    }
}


//public struct CancerCellComponent: Component, Codable {
//    public var cellID: Int? = nil
//    public var hitCount: Int = 0
//    public var isDestroyed: Bool = false
//    public var currentScale: Float = 1.0
//    public var isScaling: Bool = false  // Track if we're currently in a scaling animation
//    public var targetScale: Float = 1.0  // The scale we're animating towards
//    public var wasJustHit: Bool = false  // Track when a new hit occurs
//    public var isEmittingParticles: Bool = false  // Track particle emitter state
//    
//    /// The number of hits required to destroy this specific cancer cell
//    public var requiredHits: Int = 18  // Default to 18 for backward compatibility
//    
//    // Scale thresholds for different hit counts
//    public static let scaleThresholds: [(hits: Int, scale: Float)] = [
//        (1, 0.9),   // First hit
//        (3, 0.8),   // Third hit
//        (6, 0.7),   // Sixth hit
//        (9, 0.6),   // Ninth hit
//        (12, 0.5),  // Twelfth hit
//        (15, 0.4)   // Fifteenth hit
//    ]
//    
//    public init(cellID: Int? = nil) {
//        self.cellID = cellID
//        // Generate random required hits between 5 and 18 for new cells
//        self.requiredHits = Int.random(in: 5...18)
//        print("✨ Initializing CancerCellComponent with isEmittingParticles=\(isEmittingParticles)")
//    }
//}



// // Marker component that can be added in USDZ
 public struct CancerCellComponent: Component, Codable {
     public init() {}
 }

// // Full state component added by the system
 public struct CancerCellStateComponent: Component {
     public let parameters: CancerCellParameters
    
     public init(parameters: CancerCellParameters) {
         self.parameters = parameters
     }
 }

 @MainActor
 public class CancerCellSystem: System {
     /// Query to match cancer cell entities
     static let query = EntityQuery(where: .has(CancerCellStateComponent.self))
    
     required public init(scene: RealityKit.Scene) {}
    
     /// Update cancer cell entities
     public func update(context: SceneUpdateContext) {
         for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
             guard let stateComponent = entity.components[CancerCellStateComponent.self] else { continue }
             let parameters = stateComponent.parameters
            
             // Check if cell should be destroyed
             if parameters.hitCount >= parameters.requiredHits && !parameters.isDestroyed {
                 parameters.isDestroyed = true
                 

                 
                 print("=== Cancer Cell Death Triggered ===")
                 print("💀 Cell is destroyed")
                 
                 // Find and toggle particle emitter
                 if let particleSystem = entity.findEntity(named: "ParticleEmitter"),
                    var emitter = particleSystem.components[ParticleEmitterComponent.self] {
                     emitter.burst()
                     particleSystem.components.set(emitter)
                     print("✨ Updated particle emitter isEmitting to: \(emitter.isEmitting)")
                 } else {
                     print("⚠️ Could not find particle emitter")
                 }
                 
                 // Attempt to play the default subtree animation
                 if let animationResource = entity.availableAnimations.first {
                     entity.playAnimation(animationResource, transitionDuration: 0.0, startsPaused: false)
                 } else if let animLib = entity.components[AnimationLibraryComponent.self] {
                     // Fallback to a specific animation in the AnimationLibraryComponent
                     if let deathAnimation = animLib.animations["death"] {
                         entity.playAnimation(deathAnimation)
                     }
                 }
                 
                 // Play audio and wait for particle effect
                 if let audioComponent = entity.components[AudioLibraryComponent.self],
                    let deathSound = audioComponent.resources["Kill_Cell_5.wav"] {
                     entity.playAudio(deathSound)
                     
                     // Remove after animation and particles complete
                     Task {
                         // Wait for animation and initial particle burst
                         try? await Task.sleep(for: .seconds(2))
                         
                         // First, ensure particles are stopped
                         if let particleSystem = entity.findEntity(named: "ParticleEmitter"),
                            var emitter = particleSystem.components[ParticleEmitterComponent.self] {
                             emitter.isEmitting = false
                             particleSystem.components.set(emitter)
                             print("FINISH ✨ Stopped particle emitter")
                         }
                         
                         // Wait a bit for particles to settle
                         try? await Task.sleep(for: .seconds(1))
                         
                         // Remove all components in a specific order
                         if let particleSystem = entity.findEntity(named: "ParticleEmitter") {
                             // Remove particle component first
                             particleSystem.components.remove(ParticleEmitterComponent.self)
                             print("FINISH ✨ Removed particle emitter component")
                         }
                         
                         // Remove the cancer cell component
                         entity.components.remove(CancerCellComponent.self)
                         entity.components.remove(CancerCellStateComponent.self)
                         print("FINISH ✨ Removed cancer cell component")
                         
                         // Finally remove the entity
                         if entity.scene != nil {
                             print("✨ Removing entity from scene")
                             entity.removeFromParent()
                         }
                     }
                 }
                 continue
             }
             
             // Handle sudden scale changes based on hit count
             if parameters.isScaling {
                 let currentScale = entity.scale.x
                 let targetScale = parameters.targetScale
                 
                 // Even faster scaling with easing
                 let t = Float(15.0 * context.deltaTime) // 15x faster
                 
                 // Use exponential easing for more dramatic effect
                 let easedT = 1.0 - pow(1.0 - t, 3)  // Cubic easing
                 
                 if abs(currentScale - targetScale) > 0.001 {
                     let newScale = simd_mix(currentScale, targetScale, easedT)
                     entity.scale = [newScale, newScale, newScale]
                 } else {
                     // Animation complete
                     parameters.isScaling = false
                     entity.scale = [targetScale, targetScale, targetScale]
                 }
                 entity.components[CancerCellStateComponent.self] = stateComponent
             }
             
             // Check for hit count thresholds
             for threshold in CancerCellParameters.scaleThresholds {
                 if parameters.hitCount == threshold.hits {
                     parameters.isScaling = true
                     parameters.targetScale = threshold.scale
                     parameters.currentScale = threshold.scale
                     entity.components[CancerCellStateComponent.self] = stateComponent
                     break
                 }
             }
         }
     }
 }
