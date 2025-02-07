import SwiftUI
import RealityKit
import RealityKitContent
import OSLog


extension ADCOptimizedImmersive {
    // MARK: - Gestures
    
    func createGestureComponent() -> ADCGestureComponent {
        var gestureComponent = ADCGestureComponent(canDrag: true,
                                                      pivotOnDrag: false,
                                                      canScale: false,
                                                      canRotate: true)
        gestureComponent.onDragStarted = { entity in
            shouldAddADCAttachment = false
            shouldAddMainViewAttachment = false
            shouldAddLinkerAttachment = false
            shouldAddPayloadAttachment = false
        }
        gestureComponent.onDragEnded = { entity in
            shouldAddADCAttachment = true
            shouldAddMainViewAttachment = true
            shouldAddLinkerAttachment = true
            shouldAddPayloadAttachment = true
        }
        gestureComponent.onRotateStarted = { entity in
            shouldAddADCAttachment = false
            shouldAddMainViewAttachment = false
            shouldAddLinkerAttachment = false
            shouldAddPayloadAttachment = false
        }
        gestureComponent.onRotateEnded = { entity in
            shouldAddADCAttachment = true
            shouldAddMainViewAttachment = true
            shouldAddLinkerAttachment = true
            shouldAddPayloadAttachment = true
        }
        return gestureComponent
    }
    
    func createLinkerGestureComponent(linkerEntity: Entity, linkerTarget: Entity) -> ADCGestureComponent {
        var gestureComponent = ADCGestureComponent(canDrag: true,
                                                pivotOnDrag: false,
                                                canScale: false,
                                                canRotate: false)
        gestureComponent.onDragStarted = { entity in
            shouldAddADCAttachment = false
            shouldAddLinkerAttachment = false
            shouldAddPayloadAttachment = false
        }
        gestureComponent.onDragEnded = { entity in
            if let finishedEntity = entity {
//                os_log(.debug, "ITR..createLinkerGestureComponent(): Drag ended on entity \(finishedEntity.name)")
                shouldAddADCAttachment = true
                shouldAddLinkerAttachment = true
                shouldAddPayloadAttachment = true
                
                let currentPosition = finishedEntity.position(relativeTo: nil)
                let targetPosition = linkerTarget.position(relativeTo: nil)
                let dist = distance(currentPosition, targetPosition)
                
//                os_log(.debug, "ITR..createLinkerGestureComponent(): LinkerEntity Position: \(currentPosition), \n     LinkerTargetPosition: \(targetPosition),    Distance: \(dist)")
                if dist < 0.2 {
                    os_log(.debug, "ITR..createLinkerGestureComponent(): Entity \(finishedEntity.name) is close enough to the target linker, dataModel.linkersWorkingIndex: \(dataModel.linkersWorkingIndex)")
                    // Set default color to 0 if none selected
                    if dataModel.selectedLinkerType == nil {
                        dataModel.selectedLinkerType = 0
                    }
                    dataModel.selectedADCLinker = dataModel.selectedLinkerType
                    dataModel.placedLinkerCount += 1
                    Task { @MainActor in
                        attachPopSoundToTarget(finishedEntity)
                        await playPopSound()
                    }
                    
                    Task { @MainActor in
                        // Only apply color if one has been chosen
                        if let selectedType = dataModel.selectedLinkerType {
                            // Update all previously placed linkers
                            for index in 0..<dataModel.linkersWorkingIndex {
                                if let originalMaterial = originalLinkerMaterial {
                                    if var modelComponent = adcLinkers[index].components[ModelComponent.self] {
                                        modelComponent.materials = [originalMaterial]
                                        adcLinkers[index].components[ModelComponent.self] = modelComponent
                                    }
                                }
                                adcLinkers[index].updateShaderGraphColor(parameterName: "Basecolor_Tint", color: .adc[selectedType])
                            }
                            
                            // Update current linker
                            if let originalMaterial = originalLinkerMaterial {
                                adcLinkers[dataModel.linkersWorkingIndex].updateMaterials { material in
                                    material = originalMaterial
                                }
                            }
                            adcLinkers[dataModel.linkersWorkingIndex].updateShaderGraphColor(parameterName: "Basecolor_Tint", color: .adc[selectedType])
                        }
                        
                        // If there's a next linker, give it the outline material
                        if dataModel.linkersWorkingIndex < (adcLinkers.count - 1) {
                            if let material = outlineMaterial {
                                adcLinkers[dataModel.linkersWorkingIndex + 1].model?.materials = [material]
                            }
                        }
                        
                        adcLinkers.forEach {
                            $0.components.remove(ADCProximitySourceComponent.self)
                        }
                        
                        let isFinalLinker = dataModel.linkersWorkingIndex >= (adcLinkers.count - 1)
                        if isFinalLinker {
                            await handleFinalEntityPlacement(
                                entityType: .linker,
                                workingEntity: linkerEntity,
                                savedPosition: initialLinkerPosition,
                                nextStep: 2
                            )
                        } else {
                            if let linkerEntity = self.linkerEntity,
                               let savedPosition = initialLinkerPosition {
                                linkerEntity.position = savedPosition  // Restore to original position
                            }

                            dataModel.linkersWorkingIndex += 1

                            for (index, element) in adcLinkers.enumerated() {
                                element.isEnabled = index <= dataModel.linkersWorkingIndex
                            }
                            
                            adcLinkers[dataModel.linkersWorkingIndex].components.set(ADCProximitySourceComponent())

                        }
                        updateADC()
                    }
                } else {
//                    os_log(.debug, "ITR..createLinkerGestureComponent(): Entity \(finishedEntity.name) distance: \(dist)")
                }
            }
        }
        gestureComponent.onRotateStarted = { entity in
            shouldAddADCAttachment = false
            shouldAddLinkerAttachment = false
            shouldAddPayloadAttachment = false
        }
        gestureComponent.onRotateEnded = { entity in
            shouldAddADCAttachment = true
            shouldAddLinkerAttachment = true
            shouldAddPayloadAttachment = true
        }
        return gestureComponent
    }
    
    /// Handles the final placement of an entity (linker or payload)
    /// - Parameters:
    ///   - entityType: Type of entity being placed
    ///   - workingEntity: The current working entity to reset
    ///   - savedPosition: Original position to reset to
    ///   - nextStep: Step to advance to when complete
    func handleFinalEntityPlacement(entityType: ADCEntityType,
                                  workingEntity: Entity?,
                                  savedPosition: SIMD3<Float>?,
                                  nextStep: Int) async {
        // Reset position and hide working entity
        if let workingEntity = workingEntity,
           let savedPosition = savedPosition {
            workingEntity.position = savedPosition
            workingEntity.isEnabled = false
        }
        
        if let workingEntity = workingEntity {
            attachPopSoundToTarget(workingEntity)
            Task { @MainActor in
                await playPopSound()
            }
        }
        
        // Only advance if VO is not playing
        if !dataModel.isVOPlaying {
            let oldStep = dataModel.adcBuildStep
            try? await Task.sleep(for: .milliseconds(500))
            dataModel.adcBuildStep = nextStep
            
            // Reset selection for next step if needed
            switch entityType {
            case .linker:
                dataModel.selectedPayloadType = nil
            case .payload:
                // No reset needed for payload as it's the final step
                break
            }
            
            // Play VO for new step if step changed
            if oldStep != dataModel.adcBuildStep {
                do {
                    try await playSpatialAudio(step: dataModel.adcBuildStep)
                } catch {
                    os_log(.error, "ITR..handleFinalEntityPlacement(): ❌ Failed to play VO: \(error)")
                }
            }
        }
    }
    
    func createPayloadGestureComponent(payloadEntity: Entity, payloadTarget: Entity) -> ADCGestureComponent {
        var gestureComponent = ADCGestureComponent(canDrag: true,
                                                pivotOnDrag: false,
                                                canScale: false,
                                                canRotate: false)
        gestureComponent.onDragStarted = { entity in
            shouldAddADCAttachment = false
            shouldAddLinkerAttachment = false
            shouldAddPayloadAttachment = false
        }
        gestureComponent.onDragEnded = { entity in
            if let finishedEntity = entity {
//                os_log(.debug, "ITR..createPayloadGestureComponent(): Drag ended on entity \(finishedEntity.name)")
                shouldAddADCAttachment = true
                shouldAddLinkerAttachment = true
                shouldAddPayloadAttachment = true
                
                //TODO: check if entity is close enough to the target linker, if so then remove the working linker and set the selected Linker
                let currentPosition = finishedEntity.position(relativeTo: nil)
                let targetPosition = payloadTarget.position(relativeTo: nil)
                let dist = distance(currentPosition, targetPosition)
                
//                os_log(.debug, "ITR..createPayloadGestureComponent(): PayloadEntity Position: \(currentPosition), \n     PayloadTargetPosition: \(targetPosition),    Distance: \(dist)")
                if dist < 0.2 {
                    os_log(.debug, "ITR..createPayloadGestureComponent(): Entity \(finishedEntity.name) is close enough to the target payload, dataModel.payloadsWorkingIndex: \(dataModel.payloadsWorkingIndex)")
                    // Set default color to 0 if none selected
                    if dataModel.selectedPayloadType == nil {
                        dataModel.selectedPayloadType = 0
                    }
                    dataModel.selectedADCPayload = dataModel.selectedPayloadType
                    Task { @MainActor in
                        attachPopSoundToTarget(finishedEntity)
                        await playPopSound()
                    }
                    dataModel.placedPayloadCount += 1
                    
                    Task { @MainActor in
                        // Only apply color if one has been chosen
                        if let selectedType = dataModel.selectedPayloadType {
                            // Update all previously placed payloads
                            for index in 0..<dataModel.payloadsWorkingIndex {
                                // Inner sphere
                                if let originalInnerMaterial = originalPayloadInnerMaterial {
                                    if var modelComponent = adcPayloadsInner[index].components[ModelComponent.self] {
                                        modelComponent.materials = [originalInnerMaterial]
                                        adcPayloadsInner[index].components[ModelComponent.self] = modelComponent
                                    }
                                }
                                adcPayloadsInner[index].updatePBREmissiveColor(.adcEmissive[selectedType])
                                
                                // Outer sphere
                                if let originalOuterMaterial = originalPayloadOuterMaterial {
                                    if var modelComponent = adcPayloadsOuter[index].components[ModelComponent.self] {
                                        modelComponent.materials = [originalOuterMaterial]
                                        adcPayloadsOuter[index].components[ModelComponent.self] = modelComponent
                                    }
                                }
                                adcPayloadsOuter[index].updateShaderGraphColor(parameterName: "glowColor", color: .adc[selectedType])
                            }
                            
                            // Update current payload
                            if let originalInnerMaterial = originalPayloadInnerMaterial {
                                adcPayloadsInner[dataModel.payloadsWorkingIndex].updateMaterials { material in
                                    material = originalInnerMaterial
                                }
                            }
                            if let originalOuterMaterial = originalPayloadOuterMaterial {
                                adcPayloadsOuter[dataModel.payloadsWorkingIndex].updateMaterials { material in
                                    material = originalOuterMaterial
                                }
                            }
                            adcPayloadsInner[dataModel.payloadsWorkingIndex].updatePBREmissiveColor(.adcEmissive[selectedType])
                            adcPayloadsOuter[dataModel.payloadsWorkingIndex].updateShaderGraphColor(parameterName: "glowColor", color: .adc[selectedType])
                        }
                        
                        // If there's a next payload, give it the outline material
                        let nextIndex = dataModel.payloadsWorkingIndex + 1
                        if nextIndex < adcPayloadsInner.count && nextIndex < adcPayloadsOuter.count {
                            if let material = outlineMaterial {
                                adcPayloadsInner[nextIndex].model?.materials = [material]
                                adcPayloadsOuter[nextIndex].model?.materials = [material]
                            }
                        }
                        
                        adcPayloadsOuter.forEach {
                            $0.components.remove(ADCProximitySourceComponent.self)
                        }
                        
                        let isFinalPayload = dataModel.payloadsWorkingIndex >= (adcPayloadsInner.count - 1)
                        if isFinalPayload {
                            await handleFinalEntityPlacement(
                                entityType: .payload,
                                workingEntity: payloadEntity,
                                savedPosition: initialPayloadPosition,
                                nextStep: 3
                            )
                        } else {
                            if let payloadEntity = self.payloadEntity,
                               let savedPosition = initialPayloadPosition {
                                payloadEntity.position = savedPosition  // Restore to original position
                            }
                            
                            dataModel.payloadsWorkingIndex += 1
                            
                            for (index, element) in adcPayloadsInner.enumerated() {
                                element.isEnabled = index <= dataModel.payloadsWorkingIndex
                            }
                            for (index, element) in adcPayloadsOuter.enumerated() {
                                element.isEnabled = index <= dataModel.payloadsWorkingIndex
                            }
                            
                            adcPayloadsOuter[dataModel.payloadsWorkingIndex].components.set(ADCProximitySourceComponent())
                        }
                        updateADC()
                    }
                } else {
//                    os_log(.debug, "ITR..createPayloadGestureComponent(): Entity \(finishedEntity.name) distance: \(dist)")
                }
            }
        }
        gestureComponent.onRotateStarted = { entity in
            shouldAddADCAttachment = false
            shouldAddLinkerAttachment = false
            shouldAddPayloadAttachment = false
        }
        gestureComponent.onRotateEnded = { entity in
            shouldAddADCAttachment = true
            shouldAddLinkerAttachment = true
            shouldAddPayloadAttachment = true
        }
        return gestureComponent
    }
}
