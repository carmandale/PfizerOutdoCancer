import RealityKit
import RealityKitContent

@MainActor
public class BreathingSystem: System {
    /// Query for entities with both Transform and BreathingComponent
    static let query = EntityQuery(where: .has(BreathingComponent.self))
    
    /// Define system dependencies - run before CancerCellSystem
    public nonisolated static var dependencies: [SystemDependency] {
        [.before(CancerCellSystem.self)]
    }
    
    public required init(scene: Scene) { }
    
    public func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var breathing = entity.components[BreathingComponent.self],
                  let _ = entity.components[CancerCellComponent.self],
                  let stateComponent = entity.components[CancerCellStateComponent.self] else { continue }
            
            // Skip if cancer cell is scaling from a hit
            if stateComponent.parameters.isScaling { continue }
            
            // Update phase
            breathing.phase += (2.0 * .pi * Float(context.deltaTime)) / breathing.cycleDuration
            
            // Wrap phase between 0 and 2π
            if breathing.phase >= 2.0 * .pi {
                breathing.phase -= 2.0 * .pi
            }
            
            // Use cancer cell's current scale as the base
            breathing.baseScale = stateComponent.parameters.currentScale
            
            // Calculate scale using sine wave
            let breathingScale = breathing.baseScale + (sin(breathing.phase) * breathing.intensity)
            entity.scale = [breathingScale, breathingScale, breathingScale]
            
            // Update component
            entity.components[BreathingComponent.self] = breathing
        }
    }
} 
