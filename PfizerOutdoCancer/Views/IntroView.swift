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
                            // let portal = await PortalManager.createPortal(
                            //     appModel: appModel,
                            //     environment: immersiveSceneRoot,
                            //     portalPlaneName: "Plane_001"
                            // )
                            // portal.position = [0, 0, 0]
                            // immersiveSceneRoot.addChild(portal)
            
//            do {
//                let entity = try await appModel.assetLoadingManager.loadEntity(named: "IntroAudio3")
//                print("Successfully loaded IntroAudio")
//                immersiveSceneRoot.addChild(entity)
//                print("Added IntroAudio to immersiveSceneRoot")
//            } catch {
//                print("Failed to load IntroAudio: \(error)")
//            }
            
            // Add the immersiveSceneRoot to content
            content.add(immersiveSceneRoot)
            
            // Create head anchor for initial Y position only
            // let headAnchor = AnchorEntity(.head)
            // headAnchor.anchoring.trackingMode = .once
            // headAnchor.name = "headAnchor"
            // content.add(headAnchor)
            
            //            headAnchor.addChild(immersiveSceneRoot)
            
            // Get head Y position and offset the entire immersiveSceneRoot
            // let headY = headAnchor.position.y
            // print("Head anchor Y position: \(headY)")
            // print("Current immersiveSceneRoot position before setPosition: \(immersiveSceneRoot.position(relativeTo: nil))")
            // immersiveSceneRoot.setPosition([0, headY, 0], relativeTo: nil)
            // print("Final immersiveSceneRoot position after setPosition: \(immersiveSceneRoot.position(relativeTo: nil))")
            
        }
        .onAppear {
            // Start timer when view appears
            dismissWindow(id: AppModel.mainWindowId)
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
//        .onReceive(changeToLabReceived) { output in
//            print("🎯 Received changeToLab notification")
//            guard let entity = output.userInfo?["RealityKit.NotifyAction.SourceEntity"] as? Entity else {
//                print("⚠️ No source entity found in notification")
//                return
//            }
//            print("✅ Found source entity: \(entity.name)")
//            
//            guard appModel.currentPhase == .intro else {
//                print("❌ Wrong phase: \(appModel.currentPhase)")
//                return
//            }
//            guard !appModel.isTransitioning else {
//                print("❌ Already transitioning")
//                return
//            }
//            
//            Task {
//                print("🔄 Transitioning to Lab phase")
//                await appModel.transitionToPhase(.lab)
//            }
//        }
    }
}
