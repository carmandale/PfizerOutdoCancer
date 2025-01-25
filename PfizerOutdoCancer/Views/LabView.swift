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
            let root = appModel.labState.setupLabRoot()
            content.add(root)
            
            // Setup initial environment
            appModel.labState.setupInitialEnvironment()
            
            // Handle attachments
            if let adcButton = attachments.entity(for: "ADCBuilderViewerButton"),
               let attackButton = attachments.entity(for: "AttackCancerViewerButton") {
                
                // Find attachment points and set up buttons
                if let builderTarget = root.findEntity(named: "ADCBuilderAttachment") {
                    builderTarget.addChild(adcButton)
                    adcButton.components.set(BillboardComponent())
                    appModel.labState.adcBuilderViewerButtonEntity = adcButton
                }
                
                if let attackTarget = root.findEntity(named: "AttackCancerAttachment") {
                    attackTarget.addChild(attackButton)
                    attackButton.components.set(BillboardComponent())
                    appModel.labState.attackCancerViewerButtonEntity = attackButton
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
        .task(id: appModel.labState.mainEntity) {
            guard !appModel.labState.isSetupComplete else {
                return
            }
            
            // Load additional environment content
            try? await appModel.labState.setupEnvironment()
            
            // Start tracking
            await appModel.trackingManager.processWorldTrackingUpdates()
            await appModel.trackingManager.monitorTrackingEvents()
        }
        .onAppear {
            dismissWindow(id: AppModel.navWindowId)
            // Ensure library window starts closed
            appModel.updateLibraryWindowState(isOpen: false)
        }
        .onDisappear {
            appModel.labState.cleanup()
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
