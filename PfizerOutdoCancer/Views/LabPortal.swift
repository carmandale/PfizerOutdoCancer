/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's window view.
*/

import SwiftUI
import RealityKit

struct LabPortal: View {
    @Environment(AppModel.self) private var appModel
    /// The environment value to get the `OpenImmersiveSpaceAction` instance.
    @Environment(\.openImmersiveSpace) var openImmersiveSpace

    /// The environment value to get the `dismissImmersiveSpace` instance.
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    /// A Boolean value that indicates whether the app shows the immersive space.
    @State var immersive: Bool = false

    /// The root entity for other entities within the scene.
    private let root = Entity()

    /// A plane entity representing a portal.
    private let portalPlane = ModelEntity(
        mesh: .generatePlane(width: 1.0, height: 1.0),
        materials: [PortalMaterial()]
    )

    var body: some View {
        RealityView { content in
            await createPortal()
            content.add(root)
        }
    }

    /// Sets up the portal and adds it to the `root.`
    @MainActor func createPortal() async {
        // Create the entity that stores the content within the portal.
        let world = Entity()

        // Shrink the portal world and update the position
        // to make it fit into the portal view.
        world.scale *= 0.5
        world.position.y -= 0.5
        world.position.z -= 0.5

        // Allow the entity to be visible only through a portal.
        world.components.set(WorldComponent())
        
        do {
            // Create the box environment and add it to the root.
            guard let labEnvironment = await appModel.assetLoadingManager.instantiateEntity("lab_environment") else {
                print("Failed to load LabEnvironment from asset manager")
                return
            }
            
            
            world.addChild(labEnvironment)

            // Set up the portal to show the content in the `world`.
            portalPlane.components.set(PortalComponent(target: world))
            root.addChild(portalPlane)
        }
    }

    /// Configures the portal mesh's width and height.
    func updatePortalSize(width: Float, height: Float) {
        portalPlane.model?.mesh = .generatePlane(width: width, height: height, cornerRadius: 0.03)
    }
}



