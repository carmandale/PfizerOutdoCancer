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
    
    // MARK: extra ADCs
    func setupExtraADCs(in root: Entity) async {
        // Ensure ADC template exists
        guard let template = appModel.gameState.adcTemplate else {
            Logger.info("❌ ADC Template not found, skipping extra ADC placements")
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
        var placedCount = 0
        
        for transform in adcTransforms {
            // Clone the ADC template
            let adcClone = template.clone(recursive: true)
            
            // Generate a random rotation speed between 0.5 and 2.0
            let randomSpeed = Float.random(in: 0.5...2.0)
            
            // Create and configure a RotationComponent with the random speed
            var rotation = RotationComponent()  // assuming RotationComponent has a mutable property 'rotationSpeed'
            rotation.speed = randomSpeed
            adcClone.components.set(rotation)
            
            // Add the cloned ADC as a child of the transform entity
            transform.addChild(adcClone)
            placedCount += 1
        }
        
        Logger.info("✅ setupExtraADCs: Placed \(placedCount) ADC clones")
    }

    // MARK: Interactive ADC
    func setupADCPlacer(in root: Entity) async {
        Logger.info("""
        
        🎯 Setting up ADC Placer
        ├─ hasBuiltADC: \(appModel.hasBuiltADC)
        └─ Root Entity: \(root.name)
        """)
        
        // Only proceed if we have a built ADC
        let shouldProceed = true // appModel.hasBuiltADC
        
        guard shouldProceed,
              let placerEntity = root.findEntity(named: "ADC_placer"),
              let template = appModel.gameState.adcTemplate else {
            Logger.info("""
            
            ❌ ADC Placer Setup Failed
            ├─ shouldProceed: \(shouldProceed)
            ├─ Found Placer: \(root.findEntity(named: "ADC_placer") != nil)
            └─ Has Template: \(appModel.gameState.adcTemplate != nil)
            """)
            return
        }
        
        Logger.info("""
        
        ✅ ADC Placer Requirements Met
        ├─ Found Placer Entity: \(placerEntity.name)
        ├─ Placer Position: \(placerEntity.position)
        └─ Has Template: true
        """)
        
        // Clone and place template
        let adc = template.clone(recursive: true)
        
        // Add input target and gesture components
        adc.components.set(InputTargetComponent())
        adc.components.set(RotationComponent())
        adc.components.set(ADCGestureComponent(
            canDrag: true,
            pivotOnDrag: false,
            canScale: true,
            canRotate: true
        ))

        // setup collision
        let shape = ShapeResource.generateSphere(radius: 0.069)
        let collision = CollisionComponent(shapes: [shape])
        adc.components.set(collision)
        
        // Add to scene at placer location
        placerEntity.addChild(adc)
        adc.opacity = 0
        await adc.fadeOpacity(to: 1.0, duration: 1.0)
        
        Logger.info("""
        
        ✨ ADC Placer Setup Complete
        ├─ ADC Entity Added
        ├─ Position: \(adc.position)
        ├─ Has InputTarget: \(adc.components[InputTargetComponent.self] != nil)
        ├─ Has Rotation: \(adc.components[RotationComponent.self] != nil)
        └─ Has Gesture: \(adc.components[ADCGestureComponent.self] != nil)
        """)
    }
    
    func setupInitialLabEnvironment(in root: Entity, isIntro: Bool? = nil) async throws {
        print("📱 LabViewModel: Setting up initial environment")
        
        if isIntro != nil {
            // Intro mode - find existing lab and configure devices
            let labEnvironment = root.findEntity(named: "assembled_lab")!
            configureInteractiveDevices(in: labEnvironment)

            // Logger.debug("Attempting to setup interactive ADC for user")
            // await setupADCPlacer(in: root)
            // await setupExtraADCs(in: root)


            Logger.debug("calling setupLabEnvironment")
            try await setupLabEnvironment(in: root, isIntro: isIntro)
        } else {
            // Lab mode - load and set up the complete lab
//            guard let root = mainEntity else {
//                print("❌ LabViewModel: No root entity for initial environment")
//                return
//            }
//            
//            // Load the complete assembled lab
//            print("📱 Loading assembled lab environment")
//            let labEnvironment = try await appModel.assetLoadingManager.loadAssembledLab()
//            root.addChild(labEnvironment)
//            print("🏢 Assembled Lab Environment added to MainEntity")
//            print("📍 Lab Environment position: \(labEnvironment.position)")
//            
//            // Configure the interactive devices
//            configureInteractiveDevices(in: labEnvironment)
//
//            Logger.debug("Attempting to setup interactive ADC for user")
//            setupADCPlacer(in: root)
//
//            Logger.debug("calling setupLabEnvironment")
//            try await setupLabEnvironment(in: root, isIntro: isIntro)
        }
    }
    
    // MARK: - Environment Setup
    func setupLabEnvironment(in root: Entity, isIntro: Bool? = nil) async throws {
        Logger.info("\n=== Lab Environment Setup ===")
        Logger.info("📱 LabViewModel: Starting environment setup")
        Logger.info("🔍 isIntro parameter: \(String(describing: isIntro))")
        

        let showADC = appModel.hasBuiltADC // set to true to debug 
        
        if isIntro == nil {
            // Lab mode - check for main entity
            guard mainEntity != nil else {
                Logger.error("❌ LabViewModel: No root entity for environment setup")
                throw AssetError.resourceNotFound
            }
        }
        
        Logger.info("""
        
        🔍 ADC Button State Check
        ├─ hasBuiltADC: \(appModel.hasBuiltADC)
        ├─ Current shouldShowADCButton: \(shouldShowADCButton)
        └─ isIntro Mode: \(String(describing: isIntro))
        """)
        
        // Set ADC button visibility based on previous build
        shouldShowADCButton = showADC // appModel.hasBuiltADC
        Logger.info("🎯 ADC Button visibility set to: \(shouldShowADCButton)")
        
        // Only start the timer for ADC button if it's not already visible
        if !shouldShowADCButton {
            Logger.info("""
            
            ⏲️ Starting 30-second timer for ADC button visibility
            ├─ Current shouldShowADCButton: \(shouldShowADCButton)
            └─ hasBuiltADC: \(appModel.hasBuiltADC)
            """)
            Task {
                try? await Task.sleep(for: .seconds(40.5))
                Logger.info("⏲️ Timer complete - showing ADC button")
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    shouldShowADCButton = true
                }
            }
        } else {
            Logger.info("""
            
            🎯 Skipping ADC button timer
            ├─ Current shouldShowADCButton: \(shouldShowADCButton)
            └─ hasBuiltADC: \(appModel.hasBuiltADC)
            """)
        }
        
        // Load and add lab VO (timeline will play automatically)
        Logger.info("\n🎙️ Attempting to load lab VO...")
        do {
            let labVO = try await appModel.assetLoadingManager.instantiateAsset(
                withName: "lab_vo",
                category: .labEnvironment
            )
            Logger.info("✅ Lab VO asset loaded successfully")
            root.addChild(labVO)
            Logger.info("✅ Lab VO added to root entity")
        } catch {
            Logger.error("❌ Failed to load lab VO: \(error)")
        }

        Logger.info("\n🔊 Loading lab audio Spatial Ambience...")
        do {
            let labAudio = try await appModel.assetLoadingManager.instantiateAsset(
                withName: "lab_audio",
                category: .labEnvironment
            )
            root.addChild(labAudio)
            labAudioEntity = labAudio
            Logger.info("✅ Lab Audio added to MainEntity")
        } catch {
            Logger.error("❌ Failed to load lab audio: \(error)")
        }
        
        isSetupComplete = true
        Logger.info("""
        
        ✅ Lab Environment Setup Complete
        ├─ isSetupComplete: \(isSetupComplete)
        ├─ shouldShowADCButton: \(shouldShowADCButton)
        └─ hasBuiltADC: \(appModel.hasBuiltADC)
        """)
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
        
        // Reset state, but preserve ADC button state if ADC has been built
        isSetupComplete = false
        isLibraryOpen = false
        
        // Only reset shouldShowADCButton if we haven't built an ADC
        if !appModel.hasBuiltADC {
            shouldShowADCButton = false
        }
        
        print("✅ Completed LabViewModel cleanup\n")
    }
}
