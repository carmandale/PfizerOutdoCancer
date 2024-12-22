//import RealityKit
//import Foundation
//import RealityKitContent
//
///// A system that manages cancer cell behavior
//@MainActor
//public class CancerCellSystem: System {
//    /// Query for entities with CancerCell component
//    static let query = EntityQuery(where: .has(CancerCellComponent.self))
//    
//    /// Cached audio resource
//    private var destructionAudioResource: AudioFileResource?
//    
//    /// Initialize the system with the RealityKit scene
//    public required init(scene: Scene) {
//    }
//    
//    /// Update cancer cell entities
//    public func update(context: SceneUpdateContext) {
//        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
//            guard var component = entity.components[CancerCellComponent.self] else { continue }
//            
//            // // set up initial particle system state
//            // if component.hitCount <= 0 {
//            //     component.isEmittingParticles = false
//            //     print("✨ setup initial particle system state isEmittingParticles to: \(component.isEmittingParticles)")
//            //     entity.components[CancerCellComponent.self] = component
//                
//            //     // Find and toggle particle emitter
//            //     if let particleSystem = entity.findEntity(named: "ParticleEmitter"),
//            //        var emitter = particleSystem.components[ParticleEmitterComponent.self] {
//            //         // Toggle emission state based on component state
//            //         emitter.isEmitting = component.isEmittingParticles
//            //         particleSystem.components.set(emitter)
//            //         print("✨ Updated INITIAL particle emitter isEmitting to: \(emitter.isEmitting)")
//            //     } else {
//            //         print("⚠️ Could not find particle emitter")
//            //     }
//            // }
//            
//            // Check if cell should be destroyed
//            if component.hitCount >= component.requiredHits && !component.isDestroyed {
//                component.isDestroyed = true
//                entity.components[CancerCellComponent.self] = component
//                
//                print("=== Cancer Cell Death Triggered ===")
//                print("💀 Cell is destroyed")
//                
//                // Find and toggle particle emitter
//                // Toggle particle emitter state
////                print("✨ Current isEmittingParticles value: \(component.isEmittingParticles)")
//                component.isEmittingParticles = true
////                print("✨ Toggled isEmittingParticles to: \(component.isEmittingParticles)")
//                entity.components[CancerCellComponent.self] = component
//                
//                // Find and toggle particle emitter
//                if let particleSystem = entity.findEntity(named: "ParticleEmitter"),
//                   var emitter = particleSystem.components[ParticleEmitterComponent.self] {
//                    // Toggle emission state based on component state
////                    emitter.isEmitting = component.isEmittingParticles
//                    emitter.burst()
//                    particleSystem.components.set(emitter)
//                    print("✨ Updated particle emitter isEmitting to: \(emitter.isEmitting)")
//                } else {
//                    print("⚠️ Could not find particle emitter")
//                }
//
//
//                
//                // Attempt to play the default subtree animation
//                if let animationResource = entity.availableAnimations.first {
//                    entity.playAnimation(animationResource, transitionDuration: 0.0, startsPaused: false)
//                } else if let animLib = entity.components[AnimationLibraryComponent.self] {
//                    // Fallback to a specific animation in the AnimationLibraryComponent
//                    if let deathAnimation = animLib.animations["death"] {
//                        entity.playAnimation(deathAnimation)
//                    }
//                }
//
//                
//                // Play audio and wait for particle effect
//                if let audioComponent = entity.components[AudioLibraryComponent.self],
//                   let deathSound = audioComponent.resources["Kill_Cell_5.wav"] {
//                    let controller = entity.playAudio(deathSound)
//                    
//                    // Remove after animation and particles complete
//                    Task {
//                        // Wait for animation and initial particle burst
//                        try? await Task.sleep(for: .seconds(2))
//                        
//                        // First, ensure particles are stopped
//                        if let particleSystem = entity.findEntity(named: "ParticleEmitter"),
//                           var emitter = particleSystem.components[ParticleEmitterComponent.self] {
//                            emitter.isEmitting = false
//                            particleSystem.components.set(emitter)
//                            print("FINISH ✨ Stopped particle emitter")
//                        }
//                        
//                        // Wait a bit for particles to settle
//                        try? await Task.sleep(for: .seconds(1))
//                        
//                        // Remove all components in a specific order
//                        if let particleSystem = entity.findEntity(named: "ParticleEmitter") {
//                            // Remove particle component first
//                            particleSystem.components.remove(ParticleEmitterComponent.self)
//                            print("FINISH ✨ Removed particle emitter component")
//                        }
//                        
//                        // Remove the cancer cell component
//                        entity.components.remove(CancerCellComponent.self)
//                        print("FINISH ✨ Removed cancer cell component")
//                        
//                        // Finally remove the entity
//                        if entity.scene != nil {
//                            print("✨ Removing entity from scene")
//                            entity.removeFromParent()
//                        }
//                    }
//                }
//                continue
//            }
//            
//            // Handle hit count changes and particle effects
//            // if component.wasJustHit {
//            //     print("🎯 Cancer cell was just hit")
//            //     // Reset the hit flag
//            //     component.wasJustHit = false
//                
//            //     // Toggle particle emitter state
//            //     component.isEmittingParticles = !component.isEmittingParticles
//            //     print("✨ Toggled isEmittingParticles to: \(component.isEmittingParticles)")
//            //     entity.components[CancerCellComponent.self] = component
//                
//            //     // Find and toggle particle emitter
//            //     if let particleSystem = entity.findEntity(named: "ParticleEmitter"),
//            //        var emitter = particleSystem.components[ParticleEmitterComponent.self] {
//            //         // Toggle emission state based on component state
//            //         emitter.isEmitting = component.isEmittingParticles
//            //         particleSystem.components.set(emitter)
//            //         print("✨ Updated particle emitter isEmitting to: \(emitter.isEmitting)")
//            //     } else {
//            //         print("⚠️ Could not find particle emitter")
//            //     }
//            // }
//            
//            // Handle sudden scale changes based on hit count
//            if component.isScaling {
//                let currentScale = entity.scale.x
//                let targetScale = component.targetScale
//                
//                // Even faster scaling with easing
//                let t = Float(15.0 * context.deltaTime) // 15x faster
//                
//                // Use exponential easing for more dramatic effect
//                let easedT = 1.0 - pow(1.0 - t, 3)  // Cubic easing
//                
//                if abs(currentScale - targetScale) > 0.001 {
//                    let newScale = simd_mix(currentScale, targetScale, easedT)
//                    entity.scale = [newScale, newScale, newScale]
//                } else {
//                    // Animation complete
//                    component.isScaling = false
//                    entity.scale = [targetScale, targetScale, targetScale]
//                }
//                entity.components[CancerCellComponent.self] = component
//            }
//            
//            // Check for hit count thresholds
//            for threshold in CancerCellComponent.scaleThresholds {
//                if component.hitCount == threshold.hits {
//                    // Immediately start scaling down
//                    component.isScaling = true
//                    component.targetScale = threshold.scale
//                    component.currentScale = threshold.scale
//                    
//                    entity.components[CancerCellComponent.self] = component
//                    break
//                }
//            }
//        }
//    }
//}
