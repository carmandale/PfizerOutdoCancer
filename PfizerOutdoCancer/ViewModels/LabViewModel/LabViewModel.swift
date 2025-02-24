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
    
    // ADC template reference
    var adcTemplate: Entity?
    
    // State
    var isSetupComplete = false
    var isLibraryOpen = false
    var shouldShowADCButton = false
    
    // Dependencies
    var appModel: AppModel!
    
    // MARK: - Setup Methods
    func setupRoot() -> Entity {
        Logger.debug("""
        
        === LAB ROOT SETUP ===
        ├─ Main Entity: \(mainEntity != nil)
        └─ Scene Ready: \(scene != nil)
        """)
        
        let root = Entity()
        root.name = "MainEntity"
        root.components.set(PositioningComponent(
            offsetX: 0,
            offsetY: -1.425,
            offsetZ: -0.25
        ))
        
        // Validate root setup
        guard root.components[PositioningComponent.self] != nil else {
            Logger.error("❌ Failed to configure root positioning")
            return root
        }
        
        mainEntity = root
        
        Logger.debug("""
        
        ✅ Root Setup Complete
        ├─ Entity Name: \(root.name)
        ├─ Position: \(root.position)
        └─ Has Positioning: true
        """)
        
        return root
    }
    
    // MARK: extra ADCs
    func setupExtraADCs(in root: Entity) async {
        Logger.debug("""
        
        === EXTRA ADCs SETUP ===
        ├─ Root Entity: \(root.name)
        └─ Has Template: \(appModel.gameState.adcTemplate != nil)
        """)
        
        // Ensure ADC template exists
        guard let template = appModel.gameState.adcTemplate else {
            Logger.error("❌ ADC Template not found, skipping extra ADC placements")
            return
        }
        
        // Recursive function to find all entities with names containing "ADC_xform"
        func findADCTransforms(in entity: Entity) -> [Entity] {
            var results: [Entity] = []
            if entity.name.contains("ADC_xform") {
                results.append(entity)
            }
            for child in entity.children {
                results.append(contentsOf: findADCTransforms(in: child))
            }
            return results
        }
        
        let adcTransforms = findADCTransforms(in: root)
        
        Logger.debug("""
        
        🔄 Starting ADC Placement
        ├─ Transform Points Found: \(adcTransforms.count)
        └─ Template Ready: true
        """)
        
        var placedCount = 0
        
        for transform in adcTransforms {
            let adcClone = template.clone(recursive: true)
            let randomSpeed = Float.random(in: 0.5...2.0)
            
            var rotation = RotationComponent()
            rotation.speed = randomSpeed
            adcClone.components.set(rotation)
            
            // Validate components before adding to scene
            guard adcClone.components[RotationComponent.self] != nil else {
                Logger.error("❌ Failed to configure rotation for ADC clone")
                continue
            }
            
            transform.addChild(adcClone)
            
            // Validate successful addition
            if adcClone.parent == transform {
                placedCount += 1
            }
        }
        
        Logger.debug("""
        
        ✅ Extra ADCs Setup Complete
        ├─ Attempted: \(adcTransforms.count)
        └─ Successfully Placed: \(placedCount)
        """)
    }

    // MARK: Interactive ADC
    func setupADCPlacer(in root: Entity) async {
        Logger.debug("""
        
        === ADC PLACER SETUP ===
        ├─ Root Entity: \(root.name)
        ├─ Has Built ADC: \(appModel.hasBuiltADC)
        └─ Has Template: \(appModel.gameState.adcTemplate != nil)
        """)
        
        // Only proceed if we have a built ADC
        let shouldProceed = true // appModel.hasBuiltADC
        
        guard shouldProceed,
              let placerEntity = root.findEntity(named: "ADC_placer"),
              let template = appModel.gameState.adcTemplate else {
            Logger.error("""
            
            ❌ ADC Placer Setup Failed
            ├─ Should Proceed: \(shouldProceed)
            ├─ Found Placer: \(root.findEntity(named: "ADC_placer") != nil)
            └─ Has Template: \(appModel.gameState.adcTemplate != nil)
            """)
            return
        }
        
        // Clone and place template
        let adc = template.clone(recursive: true)
        
        // Add and validate components
        adc.components.set(InputTargetComponent())
        adc.components.set(RotationComponent())
        adc.components.set(ADCGestureComponent(
            canDrag: true,
            pivotOnDrag: false,
            canScale: true,
            canRotate: true
        ))

        // Validate all required components
        guard adc.components[InputTargetComponent.self] != nil,
              adc.components[RotationComponent.self] != nil,
              adc.components[ADCGestureComponent.self] != nil else {
            Logger.error("""
            
            ❌ ADC Component Setup Failed
            ├─ Has Input: \(adc.components[InputTargetComponent.self] != nil)
            ├─ Has Rotation: \(adc.components[RotationComponent.self] != nil)
            └─ Has Gesture: \(adc.components[ADCGestureComponent.self] != nil)
            """)
            return
        }

        // Setup collision
        let shape = ShapeResource.generateSphere(radius: 0.069)
        let collision = CollisionComponent(shapes: [shape])
        adc.components.set(collision)
        
        // Add to scene and validate
        placerEntity.addChild(adc)
        
        // Validate final setup before animation
        guard adc.parent == placerEntity,
              adc.components[CollisionComponent.self] != nil else {
            Logger.error("❌ Failed to attach ADC to placer or setup collision")
            return
        }
        
        // Handle opacity animation
        adc.opacity = 0
        await adc.fadeOpacity(to: 1.0, duration: 1.0)
        
        // Final validation after animation
        Logger.debug("""
        
        ✅ ADC Placer Setup Complete
        ├─ Position: \(adc.position)
        ├─ Opacity: \(adc.opacity)
        ├─ Parent: \(adc.parent?.name ?? "none")
        └─ Components: Input, Rotation, Gesture, Collision
        """)
    }
    
    func setupInitialLabEnvironment(in root: Entity, isIntro: Bool? = nil) async throws {
        Logger.debug("""
        
        === INITIAL LAB ENVIRONMENT SETUP ===
        ├─ Root Entity: \(root.name)
        ├─ Mode: \(isIntro != nil ? "Intro" : "Standard")
        └─ Has Main Entity: \(mainEntity != nil)
        """)
        
        if isIntro != nil {
            // Validate lab environment exists before force unwrap
            guard let labEnvironment = root.findEntity(named: "assembled_lab") else {
                Logger.error("❌ Could not find assembled lab in root entity")
                throw AssetError.resourceNotFound
            }
            
            Logger.debug("""
            
            🔄 Configuring Intro Lab Environment
            ├─ Lab Entity: \(labEnvironment.name)
            └─ Parent: \(root.name)
            """)
            
            configureInteractiveDevices(in: labEnvironment)
            
            // Validate lab setup before proceeding
            guard labEnvironment.parent == root else {
                Logger.error("❌ Lab environment not properly attached to root")
                throw AssetError.resourceNotFound
            }

            Logger.debug("🔄 Starting lab environment setup...")
            try await setupLabEnvironment(in: root, isIntro: isIntro)
            
        } else {
            Logger.debug("⚠️ Standard mode lab setup not implemented")
        }
    }
    
    // MARK: - Environment Setup
    func setupLabEnvironment(in root: Entity, isIntro: Bool? = nil) async throws {
        Logger.debug("""
        
        === LAB ENVIRONMENT SETUP ===
        ├─ Root Entity: \(root.name)
        ├─ Mode: \(isIntro != nil ? "Intro" : "Standard")
        ├─ Has Built ADC: \(appModel.hasBuiltADC)
        └─ Current Button State: \(shouldShowADCButton)
        """)

        let showADC = appModel.hasBuiltADC
        
        if isIntro == nil {
            guard mainEntity != nil else {
                Logger.error("❌ No root entity for environment setup")
                throw AssetError.resourceNotFound
            }
        }
        
        // Set ADC button visibility
        shouldShowADCButton = showADC
        
        Logger.debug("""
        
        🔄 ADC Button Configuration
        ├─ Previous State: \(shouldShowADCButton)
        ├─ Has Built ADC: \(appModel.hasBuiltADC)
        └─ Show Button: \(showADC)
        """)
        
        // Timer for ADC button visibility
        if !shouldShowADCButton {
            Logger.debug("⏲️ Starting 40.5s timer for ADC button visibility")
            Task {
                try? await Task.sleep(for: .seconds(40.5))
                Logger.debug("⏲️ Timer complete - showing ADC button")
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    shouldShowADCButton = true
                }
            }
        }
        
        // Load lab VO
        Logger.debug("🔄 Loading lab voice over...")
        do {
            let labVO = try await appModel.assetLoadingManager.instantiateAsset(
                withName: "lab_vo",
                category: .labEnvironment
            )
            root.addChild(labVO)
            
            // Validate VO setup
            guard labVO.parent == root else {
                Logger.error("❌ Failed to attach lab VO to root")
                throw AssetError.resourceNotFound
            }
            Logger.debug("✅ Lab VO configured and attached")
        } catch {
            Logger.error("❌ Failed to load lab VO: \(error)")
            throw error
        }

        // Load lab audio
        Logger.debug("🔄 Loading lab spatial audio...")
        do {
            let labAudio = try await appModel.assetLoadingManager.instantiateAsset(
                withName: "lab_audio",
                category: .labEnvironment
            )
            root.addChild(labAudio)
            
            // Validate audio setup
            guard labAudio.parent == root else {
                Logger.error("❌ Failed to attach lab audio to root")
                throw AssetError.resourceNotFound
            }
            labAudioEntity = labAudio
            Logger.debug("✅ Lab audio configured and attached")
        } catch {
            Logger.error("❌ Failed to load lab audio: \(error)")
            throw error
        }
        
        isSetupComplete = true
        
        Logger.debug("""
        
        ✅ Lab Environment Setup Complete
        ├─ Setup Complete: \(isSetupComplete)
        ├─ Show ADC Button: \(shouldShowADCButton)
        ├─ Has Lab VO: \(root.findEntity(named: "lab_vo") != nil)
        ├─ Has Lab Audio: \(labAudioEntity != nil)
        └─ Has Built ADC: \(appModel.hasBuiltADC)
        """)
    }
    
    // MARK: - Attachment Setup
    func setupAttachments(attachments: RealityViewAttachments) {
        Logger.debug("""
        
        === ATTACHMENT SETUP ===
        └─ Main Entity: \(mainEntity?.name ?? "none")
        """)
        
        // Setup ADC Builder Button
        if let adbBuilderView = attachments.entity(for: "ADCBuilderViewerButton") {
            Logger.debug("🔄 Setting up ADC Builder Button...")
            
            if let builderTarget = mainEntity?.findEntity(named: "ADCBuilderAttachment") {
                Logger.debug("""
                
                🎯 Found Builder Target
                ├─ Target: \(builderTarget.name)
                └─ Position: \(builderTarget.position)
                """)
                
                builderTarget.addChild(adbBuilderView)
                adbBuilderView.components.set(BillboardComponent())
                
                // Validate setup
                guard adbBuilderView.parent == builderTarget,
                      adbBuilderView.components[BillboardComponent.self] != nil else {
                    Logger.error("❌ Failed to configure ADC builder button")
                    return
                }
                
                adcBuilderViewerButtonEntity = adbBuilderView
                Logger.debug("✅ ADC Builder Button configured")
            } else {
                Logger.error("❌ ADC Builder attachment point not found")
            }
        }
        
        // Setup Attack Cancer Button
        if let attackCancerView = attachments.entity(for: "AttackCancerViewerButton") {
            Logger.debug("🔄 Setting up Attack Cancer Button...")
            
            if let attackTarget = mainEntity?.findEntity(named: "AttackCancerAttachment") {
                Logger.debug("""
                
                🎯 Found Attack Target
                ├─ Target: \(attackTarget.name)
                └─ Position: \(attackTarget.position)
                """)
                
                attackTarget.addChild(attackCancerView)
                attackCancerView.components.set(BillboardComponent())
                
                // Validate setup
                guard attackCancerView.parent == attackTarget,
                      attackCancerView.components[BillboardComponent.self] != nil else {
                    Logger.error("❌ Failed to configure Attack Cancer button")
                    return
                }
                
                attackCancerViewerButtonEntity = attackCancerView
                Logger.debug("✅ Attack Cancer Button configured")
            } else {
                Logger.error("❌ Attack Cancer attachment point not found")
            }
        }
        
        Logger.debug("""
        
        === Attachment Setup Complete ===
        ├─ ADC Builder Button: \(adcBuilderViewerButtonEntity != nil)
        └─ Attack Cancer Button: \(attackCancerViewerButtonEntity != nil)
        """)
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
        Logger.debug("""
        
        === INTERACTIVE DEVICES SETUP ===
        └─ Root Entity: \(entity.name)
        """)
        
        let devices = findInteractiveDevices(in: entity)
        
        Logger.debug("""
        
        🔍 Device Scan Complete
        └─ Found Devices: \(devices.count)
        """)
        
        for (device, meshEntity) in devices {
            Logger.debug("""
            
            🔄 Configuring Device: \(device.name)
            ├─ Mesh: \(meshEntity.name)
            └─ Has Screen Material: \(meshEntity.components[ModelComponent.self]?.materials.contains { $0.name == "M_screen" } ?? false)
            """)
            
            if let modelComponent = meshEntity.components[ModelComponent.self],
               modelComponent.materials.contains(where: { $0.name == "M_screen" }) {
                
                let hoverEffect = HoverEffectComponent(.shader(
                    HoverEffectComponent.ShaderHoverEffectInputs(
                        fadeInDuration: 0.3,
                        fadeOutDuration: 0.2
                    )
                ))
                device.components.set(hoverEffect)
                
                // Validate hover effect setup
                guard device.components[HoverEffectComponent.self] != nil else {
                    Logger.error("❌ Failed to configure hover effect for \(device.name)")
                    continue
                }
                
                Logger.debug("✅ Configured hover effect for \(device.name)")
            }
        }
        
        Logger.debug("""
        
        === Interactive Devices Setup Complete ===
        └─ Configured Devices: \(devices.count)
        """)
    }
    
    // MARK: - Interactive Device Handling
    func handleTap(on entity: Entity) {
        Logger.debug("""
        
        === DEVICE TAP HANDLING ===
        ├─ Entity: \(entity.name)
        └─ Has Interactive Component: \(entity.components[InteractiveDeviceComponent.self] != nil)
        """)
        
        if entity.components[InteractiveDeviceComponent.self] != nil {
            Logger.debug("🔄 Found interactive device, toggling library state")
            isLibraryOpen.toggle()
            Logger.debug("✅ Library state toggled to: \(isLibraryOpen)")
        }
    }
    
    // MARK: - Cleanup
    func cleanup() {
        Logger.debug("""
        
        === LAB CLEANUP START ===
        ├─ Main Entity: \(mainEntity?.name ?? "none")
        ├─ Has Audio: \(labAudioEntity != nil)
        ├─ Has Builder Button: \(adcBuilderViewerButtonEntity != nil)
        ├─ Has Attack Button: \(attackCancerViewerButtonEntity != nil)
        └─ Current States: Setup=\(isSetupComplete), Library=\(isLibraryOpen)
        """)
        
        // Clear main entity and scene
        if let root = mainEntity {
            Logger.debug("🔄 Cleaning up main entity...")
            
            // Reset positioning component before removal
            if var positioningComponent = root.components[PositioningComponent.self] {
                Logger.debug("🔄 Resetting positioning component")
                positioningComponent.needsPositioning = true
                root.components[PositioningComponent.self] = positioningComponent
            }
            
            root.removeFromParent()
            mainEntity = nil
            scene = nil
            Logger.debug("✅ Main entity and scene cleared")
        }
        
        // Clear audio entity
        if let audio = labAudioEntity {
            Logger.debug("🔄 Removing lab audio entity")
            audio.removeFromParent()
            labAudioEntity = nil
            Logger.debug("✅ Audio entity cleared")
        }
        
        // Clear attachment entities
        if let builder = adcBuilderViewerButtonEntity {
            Logger.debug("🔄 Removing ADC builder button")
            builder.removeFromParent()
            adcBuilderViewerButtonEntity = nil
            Logger.debug("✅ Builder button cleared")
        }
        
        if let attack = attackCancerViewerButtonEntity {
            Logger.debug("🔄 Removing Attack Cancer button")
            attack.removeFromParent()
            attackCancerViewerButtonEntity = nil
            Logger.debug("✅ Attack button cleared")
        }
        
        // Reset states
        isSetupComplete = false
        isLibraryOpen = false
        
        // Only reset shouldShowADCButton if we haven't built an ADC
        if !appModel.hasBuiltADC {
            shouldShowADCButton = false
        }
        
        Logger.debug("""
        
        === LAB CLEANUP COMPLETE ===
        ├─ Main Entity: \(mainEntity == nil)
        ├─ Audio Entity: \(labAudioEntity == nil)
        ├─ Builder Button: \(adcBuilderViewerButtonEntity == nil)
        ├─ Attack Button: \(attackCancerViewerButtonEntity == nil)
        ├─ Setup Complete: \(isSetupComplete)
        ├─ Library Open: \(isLibraryOpen)
        └─ Show ADC Button: \(shouldShowADCButton)
        """)
    }
}
