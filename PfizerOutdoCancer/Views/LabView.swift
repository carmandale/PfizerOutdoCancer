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
    
    @State private var mainEntity: Entity? = nil
    @State private var isSetupComplete = false
    
    // MARK: - Scene Setup
    private func setupScenePosition(in content: RealityViewContent) async throws {
        // Create entity when needed
        let root = Entity()
        root.name = "MainEntity"

        print("🔍 Before setting component - has PositioningComponent: \(root.components[PositioningComponent.self] != nil)")
        
        root.components.set(PositioningComponent(
            offsetX: 0,
            offsetY: -1.425,
            offsetZ: 0
        ))
        
        print("🔍 After setting component - has PositioningComponent: \(root.components[PositioningComponent.self] != nil)")
        
        // Add debug cube
        let debugCube = ModelEntity(
            mesh: .generateBox(size: 0.1),
            materials: [SimpleMaterial(color: .red, isMetallic: false)]
        )
        debugCube.name = "DebugCube"
        root.addChild(debugCube)

        // Add to content before storing reference
        content.add(root)
        print("🔍 After adding to content - has PositioningComponent: \(root.components[PositioningComponent.self] != nil)")
        
        self.mainEntity = root
        print("🔍 After storing reference - has PositioningComponent: \(root.components[PositioningComponent.self] != nil)")

        print("📍 MainEntity initial position: \(root.position)")
        print("📍 DebugCube initial position: \(debugCube.position)")
    }
    
    private func setupEnvironment() async throws {
        // Load lab environment
        guard let labEnvironment = await appModel.assetLoadingManager.instantiateEntity("lab_environment") else {
            print("Failed to load LabEnvironment from asset manager")
            return
        }
        mainEntity?.addChild(labEnvironment)
        
        // Debug logging
        print("🏢 Lab Environment added to MainEntity")
        print("📍 MainEntity position after adding lab: \(String(describing: mainEntity?.position))")
        print("📍 Lab Environment position: \(labEnvironment.position)")
    }
    
    // MARK: - Attachment Setup
    private func setupAttachments(attachments: RealityViewAttachments) {
        // Setup ADC Builder Button
        if let adbBuilderView = attachments.entity(for: "ADCBuilderViewerButton") {
            print("🔧 ADCBuilderViewerButton attachment created")
            if let builderTarget = mainEntity?.findEntity(named: "ADCBuilderAttachment") {
                print("🔧 Found ADCBuilderAttachment entity at position: \(builderTarget.position)")
                builderTarget.addChild(adbBuilderView)
                adbBuilderView.components.set(BillboardComponent())
            } else {
                print("❌ ADCBuilderAttachment entity not found in scene")
            }
        }
        
        // Setup Attack Cancer Button
        if let attackCancerView = attachments.entity(for: "AttackCancerViewerButton") {
            print("🎯 AttackCancerViewerButton attachment created")
            if let attackTarget = mainEntity?.findEntity(named: "AttackCancerAttachment") {
                print("🎯 Found AttackCancerAttachment entity at position: \(attackTarget.position)")
                attackTarget.addChild(attackCancerView)
                attackCancerView.components.set(BillboardComponent())
            }
        }
    }
    
    var body: some View {
        RealityView { content, attachments in
            let contentRef = content
            
            Task {
                do {
                    // Setup in sequence
                    try await setupScenePosition(in: contentRef)
                    try await Task.sleep(for: .milliseconds(100)) // Give tracking time to initialize
                    try await setupEnvironment()
                    setupAttachments(attachments: attachments)
                    isSetupComplete = true
                } catch {
                    print("❌ Error in setup sequence: \(error)")
                }
            }
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
            // Cleanup
            mainEntity = nil
            isSetupComplete = false
        }
        .task {
            // Monitor session events
            await appModel.monitorSessionEvents()
        }
        .task {
            // Start ARKit session when view appears
            try? await appModel.runARKitSession()
        }
    }
}
