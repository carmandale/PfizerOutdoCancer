//
//  IntroView.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 10/23/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

//extension Notification.Name {
//    static let changeToLabNotification = Notification.Name("ChangeToLab")
//}

/// A RealityView that creates an immersive lab environment with spatial audio and IBL lighting
struct IntroView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissWindow) private var dismissWindow

    
    /// The root entities for the intro scene.
    let immersiveSceneRoot: Entity = Entity()
    
    /// The root entity for other entities within the scene.
    private let root = Entity()
    
    // Timer for auto-transition
    @State private var transitionTimer: Timer?

    var body: some View {
        RealityView { content in
            // Add the intro environment to the immersiveSceneRoot
            if let introEnvironmentEntity = await appModel.assetLoadingManager.instantiateEntity("intro_environment") {
                immersiveSceneRoot.addChild(introEnvironmentEntity)
            }
            
//             Create portal and add to immersiveSceneRoot
                 let portal = await PortalManager.createPortal(
                     appModel: appModel,
                     environment: immersiveSceneRoot,
                     portalPlaneName: "Plane_001"
                 )
                 portal.position = [0, 0, 0]
                 immersiveSceneRoot.addChild(portal)
            
            // Add the immersiveSceneRoot to content
            content.add(immersiveSceneRoot)
            
            
        }
        .onAppear {
            // Start timer when view appears
//            dismissWindow(id: AppModel.mainWindowId)
            transitionTimer = Timer.scheduledTimer(withTimeInterval: 144, repeats: false) { _ in
                Task {
                    await appModel.transitionToPhase(.lab)
                }
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            transitionTimer?.invalidate()
            transitionTimer = nil
        }
    }
}
