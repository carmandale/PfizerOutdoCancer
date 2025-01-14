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
    
    @State private var headTracker = HeadPositionTracker()
    @State private var subscription: EventSubscription?
    @State private var mainEntity: Entity? = nil

    private func positionMainEntity() {
        // Compensate for the difference between standing height (1.6m) and sitting height (1.15m)
        headTracker.positionEntityRelativeToUser(mainEntity, offset: [0, -1.4625, 0])
    }
    
    var body: some View {
        RealityView { content, attachments in
            // Capture content immediately
            let contentRef = content
            
            Task {

                do {
                    try await headTracker.ensureInitialized()
                    print("✅ Head tracking initialized")

                    let masterEntity = Entity()
                    self.mainEntity = masterEntity
                    self.mainEntity?.name = "MainEntity"
                    contentRef.add(masterEntity)
                    
                    // Load lab environment first
                    guard let labEnvironment = await appModel.assetLoadingManager.instantiateEntity("lab_environment") else {
                        print("Failed to load LabEnvironment from asset manager")
                        return
                    }
                    
                    masterEntity.addChild(labEnvironment)
                    
                    if let adbBuilderView = attachments.entity(for: "ADCBuilderViewerButton") {
                        print("🔧 ADCBuilderViewerButton attachment created")
                        if let builderTarget = masterEntity.findEntity(named: "ADCBuilderAttachment") {
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
                        if let attackTarget = masterEntity.findEntity(named: "AttackCancerAttachment") {
                            print("🎯 Found AttackCancerAttachment entity at position: \(attackTarget.position)")
                            attackTarget.addChild(attackCancerView)
                            attackCancerView.components.set(BillboardComponent())
                        } else {
                            print("❌ AttackCancerAttachment entity not found in scene")
                        }
                    } else {
                        print("❌ Failed to create AttackCancerViewerButton attachment")
                    }
                    
                    positionMainEntity() 
                    
                    subscription = contentRef.subscribe(to: CollisionEvents.Began.self) { [weak appModel] event in
                        appModel?.gameState.handleCollisionBegan(event)
                    }
                } catch {
                    print("❌ Error initializing head tracking: \(error)")
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
        .onAppear {
            dismissWindow(id: AppModel.debugNavigationWindowId)
        }
        .onDisappear {
            dismissWindow(id: AppModel.libraryWindowId)
        }
    }
}
