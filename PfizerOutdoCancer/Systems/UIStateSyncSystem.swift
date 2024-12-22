import RealityKit
import RealityKitContent

/// System responsible for syncing RealityKit state to UI components
class UIStateSyncSystem: System {
    static let query = EntityQuery(where: .has(CancerCellStateComponent.self))
    
    required init(scene: Scene) {}
    
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard let stateComponent = entity.components[CancerCellStateComponent.self] else { continue }
            
            // Write-through pattern: Sync from parameters to HitCountComponent
            entity.components.set(HitCountComponent(
                hitCount: stateComponent.parameters.hitCount,
                requiredHits: stateComponent.parameters.requiredHits,
                isDestroyed: stateComponent.parameters.isDestroyed
            ))
        }
    }
} 