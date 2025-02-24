//
//  AttackCancerViewModel+ADC.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 05.02.25.
//

import SwiftUI
import RealityKit
import RealityKitContent

extension AttackCancerViewModel {
    // MARK: - ADC Setup
    func setADCTemplate(_ template: Entity, dataModel: ADCDataModel) {
        Logger.debug("\n🎯 Setting up ADC Template")
        Logger.debug("- Template entity: \(template.name)")
        Logger.debug("- Antibody Color: \(String(describing: dataModel.selectedADCAntibody ?? -1))")
        Logger.debug("- Linker Color: \(String(describing: dataModel.selectedLinkerType ?? -1))")
        Logger.debug("- Payload Color: \(String(describing: dataModel.selectedPayloadType ?? -1))")
        
        // Find and apply antibody color
        if let antibody = template.findModelEntity(named: "ADC_complex") {
            if let antibodyColor = dataModel.selectedADCAntibody,
               let modelComponent = antibody.components[ModelComponent.self] {
                if modelComponent.materials.first is ShaderGraphMaterial {
                    antibody.updateShaderGraphColor(parameterName: "Basecolor_Tint", color: .adc[antibodyColor])
                    #if DEBUG
                    Logger.debug("✅ Applied antibody color: \(antibodyColor)")
                    #endif
                }
            }
        }
        
        // Find and apply linker colors (all 4)
        for i in 1...4 {
            let offsetName = "linker0\(i)_offset"
            if let linker = template.findModelEntity(named: "linker", from: offsetName) {
                if let linkerColor = dataModel.selectedLinkerType {
                    // old PBR shader
                    linker.updatePBRDiffuseColor(.adc[linkerColor])
                    // new shaderGraph material
                    linker.updateShaderGraphColor(parameterName: "Basecolor_Tint", color: .adc[linkerColor])
                    #if DEBUG
                    Logger.debug("✅ Applied linker color \(linkerColor) to \(offsetName)")
                    #endif
                }
            }
        }
        
        // Find and apply payload colors (all 4 sets of inner/outer)
        for i in 1...4 {
            let offsetName = "linker0\(i)_offset"
            if let inner = template.findModelEntity(named: "InnerSphere", from: offsetName),
               let outer = template.findModelEntity(named: "OuterSphere", from: offsetName) {
                if let payloadColor = dataModel.selectedPayloadType {
                    inner.updatePBREmissiveColor(.adcEmissive[payloadColor])
                    outer.updateShaderGraphColor(parameterName: "glowColor", color: .adc[payloadColor])
                    #if DEBUG
                    Logger.debug("✅ Applied payload color \(payloadColor) to \(offsetName)")
                    #endif
                }
            }
        }
        
        adcTemplate = template
        Logger.debug("✅ ADC template stored in gameState")
        
        Logger.debug("""

        === ADC TEMPLATE COLOR UPDATE ===
        ├─ Template Instance: \(ObjectIdentifier(template))
        ├─ Previous Template: \(adcTemplate.map { ObjectIdentifier($0) } ?? "none")
        ├─ Colors:
        │  ├─ Antibody: \(dataModel.selectedADCAntibody ?? -1)
        │  ├─ Linker: \(dataModel.selectedLinkerType ?? -1)
        │  └─ Payload: \(dataModel.selectedPayloadType ?? -1)
        └─ Is Cached Template: \(template === assetLoadingManager.entityTemplates["adc"])
        """)
            }
    
    // MARK: - ADC Spawning
    func spawnADC(from position: SIMD3<Float>, targetPoint: Entity, forCellID cellID: Int) async {
        guard let template = adcTemplate,
              let root = rootEntity else {
            return
        }
        
        totalADCsDeployed += 1
        #if DEBUG
        Logger.debug("\n=== Spawning Natural ADC ===")
        Logger.debug("Start World Position: \(position)")
        Logger.debug("Target World Position: \(targetPoint.position(relativeTo: nil))")
        Logger.debug("Target Cell ID: \(cellID)")
        Logger.debug("✅ ADC #\(totalADCsDeployed) Launched (Total Taps: \(totalTaps))")
        #endif
        
        // Set the flag for first ADC fired
        if !hasFirstADCBeenFired {
            hasFirstADCBeenFired = true
        }
        
        // Clone the template (colors will be cloned with it)
        let adc = template.clone(recursive: true)
        
        // Set up collision so that the ADC is recognized as 'adc' by cancer cells
        let shape = ShapeResource.generateSphere(radius: 0.069)
        let collision = CollisionComponent(
            shapes: [shape],
            filter: .init(group: .adc, mask: .cancerCell)
        )
        adc.components.set(collision)

        // New: Add a PhysicsBodyComponent so the ADC gets picked up by the physics simulation
        // let physicsBody = PhysicsBodyComponent(shapes: [shape], mass: 0.0, mode: .kinematic)
        // adc.components.set(physicsBody)
        
        // Update ADCComponent properties
        guard var adcComponent = adc.components[ADCComponent.self] else { return }
        adcComponent.targetCellID = cellID
        adcComponent.startWorldPosition = position  // Use the hand position
        adcComponent.proteinSpinSpeed = Float.random(in: 8.0...10.0)  // Set random spin speed per instance
        adc.components[ADCComponent.self] = adcComponent
        
        // Set initial position
        adc.position = position
        
        // Add to scene
        root.addChild(adc)
        
        // Start movement
        ADCMovementSystem.startMovement(entity: adc, from: position, to: targetPoint)
    }
    
    /// Spawns an ADC without a specific target, moving in the direction the user is looking
    func spawnUntargetedADC(from position: SIMD3<Float>) async {
        guard let template = adcTemplate,
              let root = rootEntity else {
            Logger.debug("❌ Failed to spawn untargeted ADC: missing template or root")
            return
        }
        
        // Create headPosition entity with random positioning
        let headPosition = Entity()
        headPosition.name = "headPosition"
        
        // Random offsets
        let randomX = Float.random(in: -2.0...2.0)
        let randomY = Float.random(in: 1.0...2.5)
        let randomZ = Float.random(in: -7.0...(-6.5))

        // Compensate for root entity's Z offset
        let adjustedZ = randomZ + 1.0  // Add 1.0 to compensate for headTrackingRoot's -1.0 offset

        // Set position with compensation for root offset
        headPosition.position = SIMD3<Float>(randomX, randomY, adjustedZ)
        
        // Create positioning component
        // let positioning = PositioningComponent(
        //     offsetX: randomX,
        //     offsetY: randomY,
        //     offsetZ: randomZ
        // )
        
        // Create attachment point and mark as occupied
        var attachPoint = AttachmentPoint()
        attachPoint.isOccupied = true
        attachPoint.isUntargeted = true
        
        // Add components using proper lifecycle management
        
        // try await headPosition.components.set(positioning)
        headPosition.components.set(attachPoint)
       
        // Add headPosition to the scene's root to avoid ADC root offset
        Logger.debug("DEBUG: Root entity details:")
        Logger.debug("- Name: \(root.name)")
        Logger.debug("- World position: \(root.position(relativeTo: nil))")
        Logger.debug("- Local position: \(root.position)")
        
        root.addChild(headPosition)
        
        Logger.debug("DEBUG: HeadPosition target details:")
        Logger.debug("- Local position set: \(headPosition.position)")
        Logger.debug("- World position after add: \(headPosition.position(relativeTo: nil))")
        Logger.debug("- Parent entity: \(headPosition.parent?.name ?? "none")")
        
        totalADCsDeployed += 1
        #if DEBUG
        Logger.debug("\n=== Spawning Untargeted ADC ===")
        Logger.debug("Start World Position: \(position)")
        Logger.debug("Target World Position: \(headPosition.position(relativeTo: nil))")
        Logger.debug("✅ ADC #\(totalADCsDeployed) Launched (Total Taps: \(totalTaps))")
        #endif
        
        // Set the flag for first ADC fired
        if !hasFirstADCBeenFired {
            hasFirstADCBeenFired = true
        }
        
        // Clone the template (colors will be cloned with it)
        let adc = template.clone(recursive: true)
        
        // Create ADC components
        let shape = ShapeResource.generateSphere(radius: 0.069)
        let collision = CollisionComponent(
            shapes: [shape],
            filter: .init(group: .adc, mask: .cancerCell)
        )
        
        // Set up ADC component
        guard var adcComponent = adc.components[ADCComponent.self] else { return }
        adcComponent.state = .moving  // Use moving state instead of seeking
        adcComponent.startWorldPosition = position
        adcComponent.proteinSpinSpeed = Float.random(in: 8.0...10.0)
        adcComponent.speedFactor = Float.random(in: ADCMovementSystem.speedRange)
        adcComponent.arcHeightFactor = Float.random(in: ADCMovementSystem.arcHeightRange)
        
        // Add components using proper lifecycle management
        
        adc.components.set(collision)
        adc.components.set(adcComponent)
     
        
        // Set initial position
        adc.position = position
        
        // Add to scene
        root.addChild(adc)
        
        // Start movement using headPosition entity as target
        ADCMovementSystem.startMovement(entity: adc, from: position, to: headPosition)
        
        Logger.debug("✅ Untargeted ADC spawned successfully")
    }
}
