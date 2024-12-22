//
//  LabView.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 10/23/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

/// A RealityView that creates an immersive lab environment with spatial audio and IBL lighting
struct LabView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    // @StateObject private var headTracker = {
    //     let tracker = HeadTracker()
    //     tracker.config.heightOffset = -1.0  // Set desired offset
    //     return tracker
    // }()
    
    // Store subscription to prevent deallocation
    @State private var subscription: EventSubscription?
    
    // Hand tracking for debug window
    //    @State var handTrackedEntity: Entity = {
    //        let handAnchor = AnchorEntity(.hand(.left, location: .aboveHand))
    //        return handAnchor
    //    }()
    
    var body: some View {
        RealityView { content, attachments in
            do {
                // Create lab root
                let root = Entity()
                content.add(root)
                // Load lab environment first
                guard let labEnvironment = await appModel.assetLoadingManager.instantiateEntity("lab_environment") else {
                    print("Failed to load LabEnvironment from asset manager")
                    return
                }
                
                root.addChild(labEnvironment)
                
                
                // Create head anchor for one-time positioning
                // let headAnchor = headTracker.getInitialHeadAnchor()
                // let labRoot = Entity()  // Intermediate root for positioning
                // headAnchor.addChild(labRoot)
                // labRoot.setPosition([0, -1.0, -0.6], relativeTo: headAnchor)  // Position relative to head
                
                // Add lab environment to positioned root
                // labRoot.addChild(root)
                // content.add(labRoot)
                // content.add(headAnchor)
                
                // Add hand tracked debug window
                //                content.add(handTrackedEntity)
                //                if let attachmentEntity = attachments.entity(for: "DebugNavigation") {
                ////                    attachmentEntity.components[BillboardComponent.self] = .init()
                //                    handTrackedEntity.addChild(attachmentEntity)
                //                }
                
                // Setup collision tracking separately
                // let collisionEntity = headTracker.setupCollisionTracking()
                // let collisionRoot = Entity()
                // collisionRoot.components.set(ClosureComponent(closure: { deltaTime in
                //     guard let transform = headTracker.worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime())?.originFromAnchorTransform else { return }
                //     let targetPosition = transform.translation() - Float3(0, 0, 0)
                //     collisionEntity.setPosition(targetPosition, relativeTo: nil)
                // }))
                // collisionRoot.addChild(collisionEntity)
                // content.add(collisionRoot)
                
                // setup attachment views
                if let adbBuilderView = attachments.entity(for: "ADCBuilderViewerButton") {
                    print("🔧 ADCBuilderViewerButton attachment created")
                    if let builderTarget = root.findEntity(named: "ADCBuilderAttachment") {
                        print("🔧 Found ADCBuilderAttachment entity at position: \(builderTarget.position)")
                        builderTarget.addChild(adbBuilderView)
                        adbBuilderView.components.set(BillboardComponent())
                    } else {
                        print("❌ ADCBuilderAttachment entity not found in scene")
                    }
                } else {
                    print("❌ Failed to create ADCBuilderViewerButton attachment")
                }

                if let attackCancerView = attachments.entity(for: "AttackCancerViewerButton") {
                    print("🎯 AttackCancerViewerButton attachment created")
                    if let attackTarget = root.findEntity(named: "AttackCancerAttachment") {
                        print("🎯 Found AttackCancerAttachment entity at position: \(attackTarget.position)")
                        attackTarget.addChild(attackCancerView)
                        attackCancerView.components.set(BillboardComponent())
                    } else {
                        print("❌ AttackCancerAttachment entity not found in scene")
                    }
                } else {
                    print("❌ Failed to create AttackCancerViewerButton attachment")
                }
                
                // Then subscribe to collision events
                subscription = content.subscribe(to: CollisionEvents.Began.self) { [weak appModel] event in
                    appModel?.gameState.handleCollisionBegan(event)
                }
            }
        } update: { content, attachments in
            // Update content
        } attachments: {
            Attachment(id: "ADCBuilderViewerButton") {
                ADCBuilderViewerButton()
            }
            Attachment(id: "AttackCancerViewerButton") {
                AttackCancerViewerButton()
            }
        }
//        .installGestures()
        .task {
        }
    }
}
