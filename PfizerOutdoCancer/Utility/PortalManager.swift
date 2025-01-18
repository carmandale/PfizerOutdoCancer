import SwiftUI
import RealityKit

@MainActor
final class PortalManager {
    /// Sets up the portal and adds it to the `root.`
    static func createPortal(appModel: AppModel, environment: Entity, portalPlaneName: String) async -> Entity {
        let root = Entity()
        
        // Try to find the portal plane in the environment
//        let portalPlane: Entity
//        if let existingPlane = environment.findEntity(named: portalPlaneName) {
//            print("✅ Found existing portal plane: \(portalPlaneName)")
//            portalPlane = existingPlane
//            // Add portal material to existing plane
//            if let modelEntity = portalPlane as? ModelEntity {
//                modelEntity.model?.materials = [PortalMaterial()]
//                print("Adding portal material to \(modelEntity.name)")
//            } else {
//                print("⚠️ Portal plane is not a ModelEntity, materials not updated")
//            }
//        } else {
//            print("⚠️ Could not find portal plane '\(portalPlaneName)', creating fallback plane")
//            portalPlane = ModelEntity(
//                mesh: .generatePlane(width: 1.0, height: 2.0),
//                materials: [PortalMaterial()]
//            )
//        }
        
        let portalRoot = Entity()
        portalRoot.position.y = 1.5
        portalRoot.position.z = -1.5
        
        let titleRoot = Entity()
        titleRoot.name = "titleRoot"
        titleRoot.scale *= 0.5
        titleRoot.position.z = 0.1
        
        portalRoot.addChild(titleRoot)
        
        let portalPlane = ModelEntity(
            mesh: .generatePlane(width: 2.0, height: 1.0, cornerRadius: 0.3),
            materials: [PortalMaterial()]
        )
        portalPlane.name = "portalPlane"
        
        // Set initial x-scale to 0
        var transform = portalPlane.transform
        transform.scale.x = 0
        portalPlane.transform = transform
        
        // Start scale animation
        portalPlane.animateScale(duration: 5.0)
        
        print("🎯 Created portal plane with name: \(portalPlane.name) and scale: \(portalPlane.transform.scale)")
        
        if let logo = await appModel.assetLoadingManager.instantiateEntity("pfizer_logo") {
            logo.position.y += 0.25
            titleRoot.addChild(logo)
        }
        
//        if let title = await appModel.assetLoadingManager.instantiateEntity("title_card") {
//            titleRoot.addChild(title)
//        }
        

        // Create the entity that stores the content within the portal.
        let world = Entity()

        // Shrink the portal world and update the position
        // to make it fit into the portal view.
        world.scale *= 0.55
        world.position.y -= 0.25
        world.position.z -= 4.5

        // Allow the entity to be visible only through a portal.
        world.components.set(WorldComponent())
        
        // Create the lab environment and add it to the world.
        if let labEnvironment = await appModel.assetLoadingManager.instantiateEntity("lab_environment") {
            world.addChild(labEnvironment)
        }
        
        root.addChild(world)

        // Set up the portal to show the content in the `world`.
        portalPlane.components.set(PortalComponent(target: world))
        
        portalRoot.addChild(portalPlane)
        root.addChild(portalRoot)

        return root
    }
}
