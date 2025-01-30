//
//  LabViewModel.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 1/23/25.
//

import Foundation
import RealityKit
import RealityKitContent
import SwiftUI

@Observable
@MainActor
final class LabViewModel {
    // MARK: - Properties
    var mainEntity: Entity?
    var scene: RealityKit.Scene?
    
    // Entity references
    private var labAudioEntity: Entity?
    
    // Attachment entities
    var adcBuilderViewerButtonEntity: Entity?
    var attackCancerViewerButtonEntity: Entity?
    
    // State
    var isSetupComplete = false
    var isLibraryOpen = false
    
    // Dependencies
    var appModel: AppModel!
    
    // MARK: - Setup Methods
    func setupLabRoot() -> Entity {
        print("📱 LabViewModel: Setting up root entity")
        let root = Entity()
        root.name = "MainEntity"
        root.components.set(PositioningComponent(
            offsetX: 0,
            offsetY: -1.425,
            offsetZ: -1.0
        ))
        mainEntity = root
        print("✅ LabViewModel: Root entity configured")
        return root
    }
    
    func setupInitialEnvironment() {
        print("📱 LabViewModel: Setting up initial environment")
        
        guard let root = mainEntity else {
            print("❌ LabViewModel: No root entity for initial environment")
            return
        }
        
        // Use preloaded lab environment
        if let labEnvironment = appModel?.assetLoadingManager.getLaboratory() {
            root.addChild(labEnvironment)
            print("🏢 Lab Environment added to MainEntity")
            print("📍 Lab Environment position: \(labEnvironment.position)")
            
            // Configure the interactive devices
            configureInteractiveDevices(in: labEnvironment)
        }
    }
    
    // MARK: - Environment Setup
    func setupEnvironment() async throws {
        print("📱 LabViewModel: Starting additional environment setup")
        
        guard let root = mainEntity else {
            print("❌ LabViewModel: No root entity for environment setup")
            return
        }
        
        // Add VO and Audio since these are loaded async
        if let labVO = try? await appModel?.assetLoadingManager.getLabVO() {
            root.addChild(labVO)
            print("🎙️ Lab VO added to MainEntity")
        }
        
//       if let labAudio = try? await appModel?.assetLoadingManager.getLabAudio() {
//           root.addChild(labAudio)
//           labAudioEntity = labAudio
//           print("🔊 Lab Audio added to MainEntity")
//       }
        
        isSetupComplete = true
        print("✅ LabViewModel: Environment setup complete")
    }
    
    // MARK: - Attachment Setup
    func setupAttachments(attachments: RealityViewAttachments) {
        // Setup ADC Builder Button
        if let adbBuilderView = attachments.entity(for: "ADCBuilderViewerButton") {
            print("🔧 ADCBuilderViewerButton attachment created")
            if let builderTarget = mainEntity?.findEntity(named: "ADCBuilderAttachment") {
                print("🔧 Found ADCBuilderAttachment entity at position: \(builderTarget.position)")
                builderTarget.addChild(adbBuilderView)
                adbBuilderView.components.set(BillboardComponent())
                adcBuilderViewerButtonEntity = adbBuilderView
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
                attackCancerViewerButtonEntity = attackCancerView
            }
        }
    }
    
    // MARK: - Interactive Devices
    private func findInteractiveDevices(in root: Entity) -> [(entity: Entity, meshEntity: Entity)] {
        var results: [(Entity, Entity)] = []
        
        // Check if this is a mesh entity with M_screen material
        if root.name.hasSuffix("_mesh") {
            if let modelComponent = root.components[ModelComponent.self],
               modelComponent.materials.contains(where: { $0.name == "M_screen" }) {
                // Find parent that contains "laptop" or "pcmonitor"
                var current = root.parent
                while let parent = current {
                    if parent.name.lowercased().contains("laptop") || 
                       parent.name.lowercased().contains("pcmonitor") {
                        results.append((parent, root))
                        break
                    }
                    current = parent.parent
                }
            }
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
        
        for (device, meshEntity) in devices {
            print("⚙️ Adding hover effect to: \(device.name) with mesh: \(meshEntity.name)")
            
            // Find M_screen material in the mesh entity
            if let modelComponent = meshEntity.components[ModelComponent.self],
               modelComponent.materials.contains(where: { $0.name == "M_screen" }) {
                
                // Add hover effect with shader inputs
                let hoverEffect = HoverEffectComponent(.shader(
                    HoverEffectComponent.ShaderHoverEffectInputs(
                        fadeInDuration: 0.3,
                        fadeOutDuration: 0.2
                    )
                ))
                device.components.set(hoverEffect)
            }
        }
    }
    
    // MARK: - Cleanup
    func cleanup() {
        print("🧹 LabViewModel: Starting cleanup")
        
        // Clean up lab audio
        labAudioEntity?.removeFromParent()
        labAudioEntity = nil
        adcBuilderViewerButtonEntity = nil
        attackCancerViewerButtonEntity = nil
        
        // Reset positioning when leaving view
        if var positioningComponent = mainEntity?.components[PositioningComponent.self] {
            positioningComponent.needsPositioning = true
            mainEntity?.components[PositioningComponent.self] = positioningComponent
            print("🔄 Reset positioning for next lab entry")
        }
        
        mainEntity?.removeFromParent()
        isSetupComplete = false
        print("✅ LabViewModel: Cleanup complete")
    }
    
    // MARK: - Interactive Device Handling
    func handleTap(on entity: Entity) {
        print("🎯 Tap detected on entity: \(entity.name)")
        
        if entity.components[InteractiveDeviceComponent.self] != nil {
            print("📱 Found InteractiveDeviceComponent, toggling library...")
            isLibraryOpen.toggle()
        }
    }
}
