import RealityKit
import RealityKitContent
import Foundation

/// A system that handles antigen retraction animation when ADCs attach
@MainActor
public class AntigenSystem: System {
    /// Query to find entities that have AntigenComponent
    static let query = EntityQuery(where: .has(AntigenComponent.self))
    
    // Animation parameters
    static let retractionSpeed: Float = 0.25  // Units per second
    
    public required init(scene: Scene) {}
    
    public func update(context: SceneUpdateContext) {
        let deltaTime = Float(context.deltaTime)
        
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var antigenComponent = entity.components[AntigenComponent.self] else { continue }
            
            if antigenComponent.isRetracting {
                // Update progress
                antigenComponent.retractionProgress = min(antigenComponent.retractionProgress + deltaTime * Self.retractionSpeed, 1.0)
                
                // Calculate new position
                let newY = AntigenSystem.mix(0, antigenComponent.targetY, t: antigenComponent.retractionProgress)
                var newPosition = entity.position
                newPosition.y = newY
                entity.position = newPosition
                
                // Update component
                entity.components[AntigenComponent.self] = antigenComponent
                
                // If retraction is complete, stop particle emission
                if antigenComponent.retractionProgress >= 1.0 {
                    // Look for the particle entity at the same level as the attach point
                    // if let antigenParent = entity.parent,
                    //    let particleEntity = antigenParent.parent?.findEntity(named: "particle"),
                    //    let emitterEntity = particleEntity.findEntity(named: "ParticleEmitter"),
                    //    var emitter = emitterEntity.components[ParticleEmitterComponent.self] {
                    //     emitter.isEmitting = false
                    //     emitterEntity.components[ParticleEmitterComponent.self] = emitter
                    //     print("💫 Stopped particle emission")
                    // }
                }
            }
        }
    }
    
    private static func mix(_ a: Float, _ b: Float, t: Float) -> Float {
        return a * (1 - t) + b * t
    }
}
