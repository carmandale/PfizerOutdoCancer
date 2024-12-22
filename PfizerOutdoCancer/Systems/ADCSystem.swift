import RealityKit
import RealityKitContent

@MainActor
public class ADCSystem: System {
    /// Query for entities with ADC component
    static let query = EntityQuery(where: .has(ADCComponent.self))
    
    public required init(scene: Scene) {
        // One-time setup if needed
    }
    
    public func update(context: SceneUpdateContext) {
        // Will implement necessary logic
    }
}
