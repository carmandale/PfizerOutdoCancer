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
                                                canRotate: true)
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
                if dist < 0.5 {
                    os_log(.debug, "ITR..createLinkerGestureComponent(): Entity \(finishedEntity.name) is close enough to the target linker, dataModel.linkersWorkingIndex: \(dataModel.linkersWorkingIndex)")
                    dataModel.selectedADCLinker = dataModel.selectedLinkerType
                    dataModel.placedLinkerCount += 1
                    bubblePopSound.toggle()
                    
                    Task { @MainActor in
                        // First restore original material
                        if let originalMaterial = originalLinkerMaterial {
                            adcLinkers[dataModel.linkersWorkingIndex].updateMaterials { material in
                                material = originalMaterial
                            }
                        }
                        
                        // Then apply the color
                        adcLinkers[dataModel.linkersWorkingIndex].updatePBRDiffuseColor(.adc[dataModel.selectedLinkerType ?? 0])
                        
                        // If there's a next linker, give it the outline material
                        if dataModel.linkersWorkingIndex < (adcLinkers.count - 1) {
                            do {
                                let materialEntity = try await Entity(named: "Materials/M_outline.usda", in: realityKitContentBundle)
                                if let outlineMaterial = materialEntity.findEntity(named: "Sphere")?.components[ModelComponent.self]?.materials.first {
                                    adcLinkers[dataModel.linkersWorkingIndex + 1].model?.materials = [outlineMaterial]
                                }
                            } catch {
                                os_log(.error, "ITR..createLinkerGestureComponent(): ❌ Failed to load M_outline material: \(error)")
                            }
                        }
                        
                        adcLinkers.forEach {
                            $0.components.remove(ADCProximitySourceComponent.self)
                        }
//                        adcLinkers[dataModel.linkersWorkingIndex].components.set(ProximitySourceComponent())
                        
                        if dataModel.linkersWorkingIndex >= (adcLinkers.count - 1) {
                            dataModel.adcBuildStep = 2
                            dataModel.selectedPayloadType = 0
                        } else {
                            if let linkerEntity = self.linkerEntity,
                               let savedPosition = initialLinkerPosition {
                                linkerEntity.position = savedPosition  // Restore to original position
                                // linkerEntity.look(at: cameraEntity.scenePosition,
                                //                  from: linkerEntity.scenePosition,
                                //                  relativeTo: nil,
                                //                  forward: .positiveZ)
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
    
    func createPayloadGestureComponent(payloadEntity: Entity, payloadTarget: Entity) -> ADCGestureComponent {
        var gestureComponent = ADCGestureComponent(canDrag: true,
                                                pivotOnDrag: false,
                                                canScale: false,
                                                canRotate: true)
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
                    dataModel.selectedADCPayload = dataModel.selectedPayloadType
                    bubblePopSound.toggle()

                    Task { @MainActor in
                        // First restore original materials
                        if let innerMaterial = originalPayloadInnerMaterial {
                            adcPayloadsInner[dataModel.payloadsWorkingIndex].updateMaterials { material in
                                material = innerMaterial
                            }
                        }
                        if let outerMaterial = originalPayloadOuterMaterial {
                            os_log(.debug, "ITR..createPayloadGestureComponent(): Attempting to restore outer material: \(String(describing: outerMaterial))")
                            os_log(.debug, "ITR..createPayloadGestureComponent(): Available parameters: \(String(describing: outerMaterial.parameterNames))")
                            os_log(.debug, "ITR..createPayloadGestureComponent(): Material name: \(String(describing: outerMaterial.name))")
                            os_log(.debug, "ITR..createPayloadGestureComponent(): Current materials before restore: \(adcPayloadsOuter[dataModel.payloadsWorkingIndex].model?.materials ?? [])")
                            // Properly restore the M_glow shader material to the outer sphere
                            if var modelComponent = adcPayloadsOuter[dataModel.payloadsWorkingIndex].components[ModelComponent.self] {
                                modelComponent.materials = [outerMaterial]
                                adcPayloadsOuter[dataModel.payloadsWorkingIndex].components[ModelComponent.self] = modelComponent
                                os_log(.debug, "ITR..createPayloadGestureComponent(): Materials after restore: \(modelComponent.materials)")
                            }
                        }
                        
                        // Change all payloads to the same color, just like linkers
                        for (inner, outer) in zip(adcPayloadsInner, adcPayloadsOuter) {
                            inner.updatePBREmissiveColor(.adcEmissive[dataModel.selectedPayloadType ?? 0])
                            outer.updateShaderGraphColor(parameterName: "glowColor", color: .adc[dataModel.selectedPayloadType ?? 0])
                        }
                        
                        // If there's a next payload, give it the outline material
                        if dataModel.payloadsWorkingIndex < (adcPayloadsInner.count - 1) {
                            // Enable and show outline on next payload
                            adcPayloadsInner[dataModel.payloadsWorkingIndex + 1].isEnabled = true
                            adcPayloadsOuter[dataModel.payloadsWorkingIndex + 1].isEnabled = true
                        }
                        
                        adcPayloadsOuter.forEach {
                            $0.components.remove(ADCProximitySourceComponent.self)
                        }
//                        adcPayloadsOuter[dataModel.payloadsWorkingIndex].components.set(ProximitySourceComponent())
                        
                        if dataModel.payloadsWorkingIndex >= (adcPayloadsInner.count - 1) {
                            dataModel.adcBuildStep = 3
                        } else {
                            if let payloadEntity = self.payloadEntity,
                               let savedPosition = initialPayloadPosition {
                                payloadEntity.position = savedPosition  // Use saved position
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
                    dataModel.placedPayloadCount += 1
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
