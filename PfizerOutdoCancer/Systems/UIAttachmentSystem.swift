import RealityKit
import RealityKitContent
import SwiftUI

@MainActor
public class UIAttachmentSystem: System {
    /// Query for entities with both CancerCell marker and UIAttachment components
    static let query = EntityQuery(where: .has(CancerCellComponent.self) && .has(CancerCellStateComponent.self) && .has(UIAttachmentComponent.self))
    
    public required init(scene: RealityKit.Scene) {}
    
    public func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            if let _ = entity.components[UIAttachmentComponent.self],
               let _ = entity.components[CancerCellComponent.self],
               let _ = entity.components[CancerCellStateComponent.self] {
                // The system doesn't need to do much here since:
                // 1. The attachment position is handled by RealityKit (parent-child relationship)
                // 2. The hit count is managed in CancerCellStateComponent
                // 3. The UI updates automatically through SwiftUI bindings
                
                // We could add additional logic here if needed, such as:
                // - Updating attachment visibility based on distance/angle to camera
                // - Animating the attachment position/rotation
                // - Handling attachment lifecycle (creation/destruction)
            }
        }
    }
}
