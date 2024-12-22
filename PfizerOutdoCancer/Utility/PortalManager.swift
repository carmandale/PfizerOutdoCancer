import SwiftUI
import RealityKit

@MainActor
final class PortalManager {
    /// Sets up the portal and adds it to the `root.`
    static func createPortal(appModel: AppModel, environment: Entity, portalPlaneName: String) async -> Entity {
        let root = Entity()
        
        // Try to find the portal plane in the environment
        let portalPlane: Entity
        if let existingPlane = environment.findEntity(named: portalPlaneName) {
            print("✅ Found existing portal plane: \(portalPlaneName)")
            portalPlane = existingPlane
            // Add portal material to existing plane
            if let modelEntity = portalPlane as? ModelEntity {
                modelEntity.model?.materials = [PortalMaterial()]
            } else {
                print("⚠️ Portal plane is not a ModelEntity, materials not updated")
            }
        } else {
            print("⚠️ Could not find portal plane '\(portalPlaneName)', creating fallback plane")
            portalPlane = ModelEntity(
                mesh: .generatePlane(width: 1.0, height: 2.0),
                materials: [PortalMaterial()]
            )
        }
        
        // Create the entity that stores the content within the portal.
        let world = Entity()

        // Shrink the portal world and update the position
        // to make it fit into the portal view.
        world.scale *= 0.35
        world.position.y -= 0.5
        world.position.z -= 1.5

        // Allow the entity to be visible only through a portal.
        world.components.set(WorldComponent())
        
        // Create the box environment and add it to the root.
        guard let labEnvironment = await appModel.assetLoadingManager.instantiateEntity("lab_environment") else {
            print("❌ Failed to load LabEnvironment from asset manager")
            return root
        }
        
        world.addChild(labEnvironment)

        // Set up the portal to show the content in the `world`.
        portalPlane.components.set(PortalComponent(target: world))
        root.addChild(portalPlane)
        root.addChild(world)

        return root 
    }
}
