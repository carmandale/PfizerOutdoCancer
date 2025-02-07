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
    var shouldShowADCButton = false
    
    // Dependencies
    var appModel: AppModel!
    
    // MARK: - Setup Methods
    func setupRoot() -> Entity {
        print("📱 LabViewModel: Setting up root entity")
        let root = Entity()
        root.name = "MainEntity"
        root.components.set(PositioningComponent(
            offsetX: 0,
            offsetY: -1.425,
            offsetZ: -0.25
        ))
        mainEntity = root
        print("✅ LabViewModel: Root entity configured")
        return root
    }
    
    func setupInitialEnvironment() async throws {
        print("📱 LabViewModel: Setting up initial environment")
        
        guard let root = mainEntity else {
            print("❌ LabViewModel: No root entity for initial environment")
            return
        }
        
        // Load the complete assembled lab
        print("📱 Loading assembled lab environment")
        let labEnvironment = try await appModel.assetLoadingManager.loadAssembledLab()
        root.addChild(labEnvironment)
        print("🏢 Assembled Lab Environment added to MainEntity")
        print("📍 Lab Environment position: \(labEnvironment.position)")
        
        // Configure the interactive devices
        configureInteractiveDevices(in: labEnvironment)
    }
    
    // MARK: - Environment Setup
    func setupEnvironment() async throws {
        print("📱 LabViewModel: Starting environment setup")
        
        guard let root = mainEntity else {
            print("❌ LabViewModel: No root entity for environment setup")
            throw AssetError.resourceNotFound
        }
        
        print("\n=== Configuring ADC Button Visibility ===")
        if appModel.hasBuiltADC {
            print("🎯 ADC previously built - showing button immediately")
            print("🔇 Skipping lab VO playback")
            shouldShowADCButton = true
        } else {
            print("🎯 First visit - following standard introduction flow")
            // Load and play VO
            let labVO = try await appModel.assetLoadingManager.instantiateAsset(
                withName: "lab_vo",
                category: .labEnvironment
            )
            root.addChild(labVO)
            print("🎙️ Lab VO added to MainEntity")
            
            // Start the timer for ADC button
            print("⏲️ Starting 30-second timer for ADC button visibility")
            shouldShowADCButton = false  // Ensure it starts hidden
            Task {
                try? await Task.sleep(for: .seconds(38))
                print("⏲️ Timer complete - showing ADC button")
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    shouldShowADCButton = true
                }
            }
        }
        print("=== ADC Button Configuration Complete ===\n")
        
        let labAudio = try await appModel.assetLoadingManager.instantiateAsset(
            withName: "lab_audio",
            category: .labEnvironment
        )
        root.addChild(labAudio)
        labAudioEntity = labAudio
        print("🔊 Lab Audio added to MainEntity")
        
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
    
    // MARK: - Interactive Device Handling
    func handleTap(on entity: Entity) {
        print("🎯 Tap detected on entity: \(entity.name)")
        
        if entity.components[InteractiveDeviceComponent.self] != nil {
            print("📱 Found InteractiveDeviceComponent, toggling library...")
            isLibraryOpen.toggle()
        }
    }
    
    // MARK: - Cleanup
    func cleanup() {
        print("\n=== Starting LabViewModel Cleanup ===")
        
        // Clear main entity and scene
        if let root = mainEntity {
            print("🗑️ Removing main entity")
            // Reset positioning component before removal
            if var positioningComponent = root.components[PositioningComponent.self] {
                print("🎯 Resetting positioning component")
                positioningComponent.needsPositioning = true
                root.components[PositioningComponent.self] = positioningComponent
            }
            root.removeFromParent()
        }
        mainEntity = nil
        scene = nil
        
        // Clear audio entity
        if let audio = labAudioEntity {
            print("🔊 Removing lab audio entity")
            audio.removeFromParent()
        }
        labAudioEntity = nil
        
        // Clear attachment entities
        if let builder = adcBuilderViewerButtonEntity {
            print("🔧 Removing ADC builder button")
            builder.removeFromParent()
        }
        adcBuilderViewerButtonEntity = nil
        
        if let attack = attackCancerViewerButtonEntity {
            print("🎯 Removing Attack Cancer button")
            attack.removeFromParent()
        }
        attackCancerViewerButtonEntity = nil
        
        // Reset state
        isSetupComplete = false
        isLibraryOpen = false
        shouldShowADCButton = false  // Reset the button state
        
        print("✅ Completed LabViewModel cleanup\n")
    }
}
