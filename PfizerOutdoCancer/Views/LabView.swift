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
    @State private var isLibraryOpen = false
    
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
    
    // MARK: Environment Setup
    
    private func setupEnvironment() async throws {
        // Load lab environment
        if let labEnvironment = await appModel.assetLoadingManager.instantiateEntity("lab_environment") {
            mainEntity?.addChild(labEnvironment)
            // Configure the interactive devices
            // configureInteractiveDevices(in: labEnvironment)
            
            // Debug logging - moved inside if let scope
            print("🏢 Lab Environment added to MainEntity")
            print("📍 MainEntity position after adding lab: \(String(describing: mainEntity?.position))")
            print("📍 Lab Environment position: \(labEnvironment.position)")
        }
        
        if let labVO = await appModel.assetLoadingManager.instantiateEntity("lab_vo") {
            mainEntity?.addChild(labVO)
            print(">>> Lab VO added to MainEntity")
        }
    }
    
    // MARK: - Attachment Setup
    ///
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
    
    // MARK: Configure Interactive Devices
    private func findInteractiveDevices(in root: Entity) -> [Entity] {
        var results = [Entity]()
        
        // Check root itself
        if root.name.lowercased().contains("laptop") || 
           root.name.lowercased().contains("pcmonitor") {
            results.append(root)
        }
        
        // Search children
        for child in root.children {
            results.append(contentsOf: findInteractiveDevices(in: child))
        }
        
        return results
    }

    private func configureInteractiveDevices(in entity: Entity) {
        // Find and configure all interactive devices
        let devices = findInteractiveDevices(in: entity)
        print("\n=== Configuring Interactive Devices ===")
        print("🔍 Found \(devices.count) potential interactive devices")
        
        for device in devices {
            print("⚙️ Configuring device: \(device.name)")
            device.components[CollisionComponent.self] = CollisionComponent(shapes: [.generateBox(width: 0.1, height: 0.1, depth: 0.1)])
            device.components[InputTargetComponent.self] = InputTargetComponent()
            device.components[InteractiveDeviceComponent.self] = InteractiveDeviceComponent()
            print("✅ Added components to: \(device.name)")
        }
        
        print("🎯 Configured \(devices.count) interactive devices")
    }
    
    // MARK: - View
    
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
            // Ensure library window starts closed
        }
        .onDisappear {
            mainEntity?.removeFromParent()
            mainEntity = nil
//            dismissWindow(id: AppModel.libraryWindowId)
            isSetupComplete = false
        }
        .task {
            await appModel.trackingManager.processWorldTrackingUpdates()
        }
        .task {
            await appModel.trackingManager.monitorTrackingEvents()
        }
        .gesture(makeTapGesture())
    }
    
    private func makeTapGesture() -> some Gesture {
        SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                let tappedEntity = value.entity
                print("🎯 Tap detected on entity: \(tappedEntity.name)")

                if tappedEntity.components[InteractiveDeviceComponent.self] != nil {
                    print("📱 Found InteractiveDeviceComponent, toggling library...")
//                    appModel.toggleLibrary()
                    if !appModel.isLibraryWindowOpen {
                        openWindow(id: AppModel.libraryWindowId)
                        appModel.isLibraryWindowOpen = true
                    } else {
                        dismissWindow(id: AppModel.libraryWindowId)
                        appModel.isLibraryWindowOpen = false
                    }
                }
                
            }
    }
}
