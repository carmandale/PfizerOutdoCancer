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
    
    // MARK: - View
    var body: some View {
        RealityView { content, attachments in
            print("📱 LabView: Setting up RealityView")
            // Set up root entity
            let root = appModel.labState.setupRoot()
            content.add(root)
            
            // Setup environment in a task after root is configured
            Task { @MainActor in
                do {
                    try await appModel.labState.setupInitialEnvironment()
                    try await appModel.labState.setupEnvironment()
                    
                    // Now that environment is loaded, set up attachments
                    if let adcButton = attachments.entity(for: "ADCBuilderViewerButton"),
                       let attackButton = attachments.entity(for: "AttackCancerViewerButton") {
                        
                        // Find attachment points and set up buttons
                        if let builderTarget = root.findEntity(named: "ADCBuilderAttachment") {
                            print("🎯 Found ADCBuilderAttachment target")
                            builderTarget.addChild(adcButton)
                            adcButton.components.set(BillboardComponent())
                            appModel.labState.adcBuilderViewerButtonEntity = adcButton
                        } else {
                            print("❌ ADCBuilderAttachment target not found")
                        }
                        
                        if let attackTarget = root.findEntity(named: "AttackCancerAttachment") {
                            print("🎯 Found AttackCancerAttachment target")
                            attackTarget.addChild(attackButton)
                            attackButton.components.set(BillboardComponent())
                            appModel.labState.attackCancerViewerButtonEntity = attackButton
                        } else {
                            print("❌ AttackCancerAttachment target not found")
                        }
                    }
                } catch {
                    print("❌ LabView: Failed to setup environment: \(error)")
                }
            }
        } attachments: {
            Attachment(id: "ADCBuilderViewerButton") {
                ADCBuilderViewerButton()
            }
            Attachment(id: "AttackCancerViewerButton") {
                if appModel.hasBuiltADC {
                    AttackCancerViewerButton()
                }
            }
        }
        .task {
            await appModel.trackingManager.processWorldTrackingUpdates()
        }
        .task {
            await appModel.trackingManager.monitorTrackingEvents()
        }
        .onAppear {
            dismissWindow(id: AppModel.navWindowId)
            // Ensure library window starts closed
            appModel.updateLibraryWindowState(isOpen: false)
        }
        .onDisappear {
            // Cleanup is now handled by AssetLoadingManager during phase transitions
        }
        .onChange(of: appModel.labState.isLibraryOpen) { _, isOpen in
            if isOpen {
                openWindow(id: AppModel.libraryWindowId)
                appModel.updateLibraryWindowState(isOpen: true)
            } else {
                dismissWindow(id: AppModel.libraryWindowId)
                appModel.updateLibraryWindowState(isOpen: false)
            }
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    appModel.labState.handleTap(on: value.entity)
                }
        )
    }
}
