import SwiftUI
import RealityKit

@MainActor
final class PortalManager {
    /// Sets up the portal and adds it to the `root.`
    static func createPortal(appModel: AppModel, environment: Entity, portalPlaneName: String) async -> Entity {
        let root = Entity()

        let portalRoot = Entity()
        portalRoot.name = "portalRoot"
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
        
        
        
//        print("🎯 Created portal plane with name: \(portalPlane.name) and scale: \(portalPlane.transform.scale)")
        

        // Create the entity that stores the content within the portal.
        let world = Entity()
        world.name = "world"

        // Shrink the portal world and update the position
        // to make it fit into the portal view.
        world.scale *= 0.55
        world.position.y -= 0.25
        world.position.z -= 4.5

        // Allow the entity to be visible only through a portal.
        world.components.set(WorldComponent())
        
        // Add the provided lab environment to the world
        world.addChild(environment)
        
        root.addChild(world)

        // Set up the portal to show the content in the `world`.
        var portalComp = PortalComponent(target: world)
        portalComp.clippingMode = .disabled
        portalComp.crossingMode = .disabled
        portalPlane.components.set(portalComp)
        
        world.components[PortalCrossingComponent.self] = .init()
        
        portalRoot.addChild(portalPlane)
        root.addChild(portalRoot)

        return root
    }
}
