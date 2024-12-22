////
////  BloodVesselView.swift
////  SpawnAndAttrack
////
////  Created by Dale Carman on 12/5/24.
////
//
//
//import SwiftUI
//import RealityKit
//import RealityKitContent
//import ARKit
//
//
//struct BuildADCEnvironmentView: View {
//    @Environment(AppModel.self) private var appModel
//
//    /// The root for the follow scene.
//    let followRoot: Entity = Entity()
//    
//    /// The root for the head anchor.
//    let headAnchorRoot: Entity = Entity()
//    /// The root for the entities in the head-anchored scene.
//    let headPositionedEntitiesRoot: Entity = Entity()
//    
//    /// The root entities for the hummingbird and feeder.
//    let hummingbird: Entity = Entity()
//    let immersiveSceneRoot: Entity = Entity()
//    
//    /// The root entity for other entities within the scene.
//    private let root = Entity()
//    
//    var body: some View {
//        RealityView { content in
//            
//           if let buildADCEnvironmentEntity = await appModel.assetLoadingManager.instantiateEntity("build_adc_environment") {
//               immersiveSceneRoot.addChild(buildADCEnvironmentEntity)
//           } else {
//               print("Failed to load build_adc_environment from asset manager")
//           }
//
//            // Add the head-anchor root. Later, you add `AnchorEntity` to this.
//            content.add(headAnchorRoot)
//                
//            // Show the hummingbird and feeder using `AnchorEntity`.
//            startHeadPositionMode(content: content)
//
//        } update: { content in
//            // Switch between head-position and follow cases.
//            toggleHeadPositionModeOrFollowMode(content: content)
//        }
//        .installGestures()
//    }
//}
//
//extension BuildADCEnvironmentView {
//    /// Sets up the follow mode by removing the feeder and adding the hummingbird.
//    func startFollowMode() {
//        // MARK: Clean up the scene.
//        // Find the head anchor in the scene and remove it.
//        guard let headAnchor = headAnchorRoot.children.first(where: { $0.name == "headAnchor" }) else { return }
//        headAnchorRoot.removeChild(headAnchor)
//        
//        // Remove the feeder from the view.
//        immersiveSceneRoot.removeFromParent()
//        
//        // MARK: - Create the "follow" scene.
//        // Set the position of the root so that the hummingbird flies in from the center.
//        followRoot.setPosition([0, 1, -1], relativeTo: nil)
//        
//        // Rotate the hummingbird to face over the left shoulder, which faces the person due to the offset.
//        let orientation = simd_quatf(angle: .pi * -0.15, axis: [0, 1, 0]) * simd_quatf(angle: .pi * 0.2, axis: [1, 0, 0])
//        hummingbird.transform.rotation = orientation
//        
//        // Set the hummingbird as a subentity of its root, and move it to the top-right corner.
//        followRoot.addChild(hummingbird)
//        hummingbird.setPosition([0.4, 0.2, -1], relativeTo: followRoot)
//    }
//    
//    /// Sets up the head-position mode by enabling the feeder, creating a head anchor, and adding the hummingbird and feeder.
//    func startHeadPositionMode(content: RealityViewContent) {
//        // Create an anchor for the head and set the tracking mode to `.once`.
//        let headAnchor = AnchorEntity(.head)
//        headAnchor.anchoring.trackingMode = .once
//        headAnchor.name = "headAnchor"
//        // Add the `AnchorEntity` to the scene.
//        headAnchorRoot.addChild(headAnchor)
//        
//        // Add the feeder as a subentity of the root containing the head-positioned entities.
//        headPositionedEntitiesRoot.addChild(immersiveSceneRoot)
//
//        
//        // Add the head-positioned entities to the anchor, and set the position to be in front of the wearer.
//        headAnchor.addChild(headPositionedEntitiesRoot)
//        headPositionedEntitiesRoot.setPosition([0, 0, -0.6], relativeTo: headAnchor)
//    }
//    
//    /// Switches between the follow and head-position modes depending on the `HeadTrackState` case.
//    func toggleHeadPositionModeOrFollowMode(content: RealityViewContent) {
//        switch appModel.headTrackState {
//        case .follow:
//            startFollowMode()
//        case .headPosition:
//            startHeadPositionMode(content: content)
//        }
//    }
//}
