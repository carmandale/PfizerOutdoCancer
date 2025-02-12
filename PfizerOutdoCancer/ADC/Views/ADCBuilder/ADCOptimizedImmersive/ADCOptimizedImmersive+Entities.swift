import SwiftUI
import RealityKit
import RealityKitContent
import OSLog


extension ADCOptimizedImmersive {
    func prepareAntibodyEntities() {
        guard let antibodyRoot = antibodyRootEntity else { 
            os_log(.error, "ITR..prepareAntibodyEntities(): ❌ No antibody root entity")
            return 
        }
        
        if let antibody = antibodyRoot.findModelEntity(named: "ADC_complex") {
            self.antibodyEntity = antibody
            antibody.isEnabled = false
            
            // Add to main entity with proper hierarchy
            if let mainEntity = self.mainEntity {
                mainEntity.addChild(antibodyRoot)
                
                // Set initial position with proper transform
                antibodyRoot.position = antibodyRoot.position + antibodyRootOffset
                // Commenting out second transform to avoid double-application
                // antibodyRoot.transform.translation = [antibodyRoot.transform.translation.x,
                //                                    antibodyRoot.transform.translation.y,
                //                                    antibodyRoot.transform.translation.z]
                
                // Add mainViewEntity as child with proper transform
                mainViewEntity.position = mainViewEntity.position //  + antibodyAttachmentOffset
                // Commenting out second transform to avoid double-application
                // mainViewEntity.transform.translation = [mainViewEntity.transform.translation.x,
                //                                      mainViewEntity.transform.translation.y,
                //                                      mainViewEntity.transform.translation.z]
                antibodyRoot.addChild(mainViewEntity)
                
                // Set up gesture component with proper configuration
                let gestureComponent = createGestureComponent()
                antibodyRoot.components.set(gestureComponent)
                
                // Set up audio with proper resource handling
                if let resource = popAudioFileResource {
                    do {
                        self.popAudioPlaybackController = try popAudioEntity?.prepareAudio(resource)
                        os_log(.debug, "ITR..prepareAntibodyEntities(): ✅ Audio prepared successfully")
                    } catch {
                        os_log(.error, "ITR..prepareAntibodyEntities(): ❌ Failed to prepare audio: \(error)")
                    }
                }
                
                // Store original material with proper type checking
                if let modelComponent = antibody.components[ModelComponent.self],
                   let originalMaterial = modelComponent.materials.first as? ShaderGraphMaterial {
                    self.originalAntibodyMaterial = originalMaterial
                    os_log(.debug, "ITR..prepareAntibodyEntities(): ✅ Stored original antibody material")
                }
                
                // Apply outline material with proper component handling
                if let material = outlineMaterial,
                   var modelComponent = antibody.components[ModelComponent.self] {
                    modelComponent.materials = [material]
                    antibody.components[ModelComponent.self] = modelComponent
                    os_log(.debug, "ITR..prepareAntibodyEntities(): ✅ Applied outline material")
                    
                    // Add sort component for render order
                    if let sortGroup = adcSortGroup {
                        let sortComponent = ModelSortGroupComponent(group: sortGroup, order: 10)
                        antibody.components.set(sortComponent)
                        os_log(.debug, "ITR..prepareAntibodyEntities(): ✅ Added sort component with order 10")
                    }
                }
            } else {
                os_log(.error, "ITR..prepareAntibodyEntities(): ❌ No main entity to attach to")
            }
        } else {
            os_log(.error, "ITR..prepareAntibodyEntities(): ❌ Could not find ADC_complex entity")
        }
    }
    

    
    func prepareLinkerEntities() async {
        guard let antibodyRoot = antibodyRootEntity else { return }
        
        if let linker0 = antibodyRoot.findModelEntity(named: "linker", from: "linker01_offset"),
           let linker1 = antibodyRoot.findModelEntity(named: "linker", from: "linker02_offset"),
           let linker2 = antibodyRoot.findModelEntity(named: "linker", from: "linker03_offset"),
           let linker3 = antibodyRoot.findModelEntity(named: "linker", from: "linker04_offset") {
            
            self.adcLinkers = [linker0, linker1, linker2, linker3]
            
            // Store original material from first linker
            if let originalMaterial = linker0.components[ModelComponent.self]?.materials.first as? ShaderGraphMaterial {
                self.originalLinkerMaterial = originalMaterial
                os_log(.debug, "ITR..prepareLinkerEntities(): ✅ Stored original ShaderGraphMaterial")
            }
            
            // Apply stored outline material to all linkers
            if let material = outlineMaterial {
                self.adcLinkers.forEach { linker in
                    if var modelComponent = linker.components[ModelComponent.self] {
                        os_log(.debug, "ITR..prepareLinkerEntities(): Applying outline material to linker")
                        modelComponent.materials = [material]
                        linker.components[ModelComponent.self] = modelComponent
                        linker.isEnabled = false
                    }
                    
                    // Add sort component for render order
                    if let sortGroup = adcSortGroup {
                        let sortComponent = ModelSortGroupComponent(group: sortGroup, order: 20)
                        linker.components.set(sortComponent)
                    }
                }
                os_log(.debug, "ITR..prepareLinkerEntities(): ✅ Added sort components to linkers with order 20")
            } else {
                os_log(.error, "ITR..prepareLinkerEntities(): ❌ No outline material available")
            }
        }
    }
    
    func preparePayloadEntities() async {
        guard let antibodyRoot = antibodyRootEntity else {
            os_log(.error, "ITR..preparePayloadEntities(): ❌ No antibody root entity")
            return
        }
        
        // Find all payload entities with proper error handling
        let payloadPairs: [(inner: ModelEntity?, outer: ModelEntity?)] = [
            (antibodyRoot.findModelEntity(named: "InnerSphere", from: "linker01_offset"),
             antibodyRoot.findModelEntity(named: "OuterSphere", from: "linker01_offset")),
            (antibodyRoot.findModelEntity(named: "InnerSphere", from: "linker02_offset"),
             antibodyRoot.findModelEntity(named: "OuterSphere", from: "linker02_offset")),
            (antibodyRoot.findModelEntity(named: "InnerSphere", from: "linker03_offset"),
             antibodyRoot.findModelEntity(named: "OuterSphere", from: "linker03_offset")),
            (antibodyRoot.findModelEntity(named: "InnerSphere", from: "linker04_offset"),
             antibodyRoot.findModelEntity(named: "OuterSphere", from: "linker04_offset"))
        ]
        
        // Process payload pairs with proper component handling
        for (inner, outer) in payloadPairs {
            if let innerPayload = inner, let outerPayload = outer {
                // Set up inner payload
                innerPayload.isEnabled = false
                if var modelComponent = innerPayload.components[ModelComponent.self] {
                    // Store original inner material
                    if let originalMaterial = modelComponent.materials.first as? PhysicallyBasedMaterial {
                        self.originalPayloadInnerMaterial = originalMaterial
                        os_log(.debug, "ITR..preparePayloadEntities(): ✅ Stored original inner PBR material for payload %{public}@", String(describing: innerPayload.name))
                    } else {
                        os_log(.error, "ITR..preparePayloadEntities(): ❌ Failed to get original PBR material for inner payload %{public}@", String(describing: innerPayload.name))
                    }
                    modelComponent.materials = [outlineMaterial].compactMap { $0 }
                    innerPayload.components[ModelComponent.self] = modelComponent
                    
                    // Add sort component for inner payload
                    if let sortGroup = adcSortGroup {
                        let sortComponent = ModelSortGroupComponent(group: sortGroup, order: 30)
                        innerPayload.components.set(sortComponent)
                        os_log(.debug, "ITR..preparePayloadEntities(): ✅ Added sort component to inner payload with order 30")
                    }
                } else {
                    os_log(.error, "ITR..preparePayloadEntities(): ❌ No ModelComponent found for inner payload %{public}@", String(describing: innerPayload.name))
                }
                adcPayloadsInner.append(innerPayload)
                
                // Set up outer payload
                outerPayload.isEnabled = false
                if var modelComponent = outerPayload.components[ModelComponent.self] {
                    // Store original outer material
                    if let originalMaterial = modelComponent.materials.first as? ShaderGraphMaterial {
                        self.originalPayloadOuterMaterial = originalMaterial
                        os_log(.debug, "ITR..preparePayloadEntities(): ✅ Stored original outer shader material for payload %{public}@", String(describing: outerPayload.name))
                        
                        // Log available parameters for debugging
                        let parameters = originalMaterial.parameterNames
                        os_log(.debug, "ITR..preparePayloadEntities(): 📝 Available shader parameters for %{public}@: %{public}@", String(describing: outerPayload.name), parameters.joined(separator: ", "))
                    } else {
                        os_log(.error, "ITR..preparePayloadEntities(): ❌ Failed to get original shader material for outer payload %{public}@", String(describing: outerPayload.name))
                    }
                    modelComponent.materials = [outlineMaterial].compactMap { $0 }
                    outerPayload.components[ModelComponent.self] = modelComponent
                    
                    // Add sort component for outer payload
                    if let sortGroup = adcSortGroup {
                        let sortComponent = ModelSortGroupComponent(group: sortGroup, order: 40)
                        outerPayload.components.set(sortComponent)
                        os_log(.debug, "ITR..preparePayloadEntities(): ✅ Added sort component to outer payload with order 40")
                    }
                } else {
                    os_log(.error, "ITR..preparePayloadEntities(): ❌ No ModelComponent found for outer payload %{public}@", String(describing: outerPayload.name))
                }
                adcPayloadsOuter.append(outerPayload)
                
                // Ensure proper transform binding
                innerPayload.transform = Transform(scale: .one,
                                                rotation: .init(),
                                                translation: innerPayload.position)
                outerPayload.transform = Transform(scale: .one,
                                                rotation: .init(),
                                                translation: outerPayload.position)
            } else {
                os_log(.error, "ITR..preparePayloadEntities(): ❌ Failed to find payload pair")
            }
        }
        
        os_log(.debug, "ITR..preparePayloadEntities(): ✅ Found \(adcPayloadsInner.count) inner payloads and \(adcPayloadsOuter.count) outer payloads")
    }
    
    func prepareTargetEntities(antibodyScene: Entity) {
        guard adcLinkers.count > 0 else {
            os_log(.error, "ITR..prepareTargetEntities(): ❌ Error, self.adcLinkers is empty. It should have content at this point.")
            return
        }

        guard !adcPayloadsInner.isEmpty else {
            os_log(.error, "ITR..prepareTargetEntities(): ❌ Error, self.adcPayloadsInner is empty. It should have content at this point.")
            return
        }

        if let linker = antibodyScene.findEntity(named: "targetLinker"),
           let payload = antibodyScene.findEntity(named: "targetPayload"),
           let workingLinker = linker.findModelEntity(named: "linker"),
           let workingPayloadInner = payload.findModelEntity(named: "InnerSphere"),
           let workingPayloadOuter = payload.findModelEntity(named: "OuterSphere") {
            
            // Attach audio to target entities
            attachPopSoundToTarget(linker)
            attachPopSoundToTarget(payload)
            
            linkerEntity = linker
            antibodyRootEntity?.addChild(linker)
            linker.position = linker.position + linkerAttachmentOffset
            initialLinkerPosition = linker.position  // Save initial position
            
            linker.isEnabled = false
            linker.components.set(createLinkerGestureComponent(linkerEntity: linker, linkerTarget: adcLinkers[dataModel.linkersWorkingIndex]))
            workingLinker.components.set(ADCProximityComponent(minScale: 0.3, maxScale: 1.0, minProximity: 0.1, maxProximity: 0.5))
            
            payloadEntity = payload
            payload.isEnabled = false
            payload.components.set(createPayloadGestureComponent(payloadEntity: payload, payloadTarget: adcPayloadsInner[dataModel.payloadsWorkingIndex]))
            
            antibodyRootEntity?.addChild(payload)
            payload.position = payload.position + payloadAttachmentOffset
            initialPayloadPosition = payload.position  // Save initial position
            
            // Apply outline material to draggable linker
            if let material = outlineMaterial {
                if var modelComponent = workingLinker.components[ModelComponent.self] {
                    modelComponent.materials = [material]
                    workingLinker.components[ModelComponent.self] = modelComponent
                    os_log(.debug, "ITR..prepareTargetEntities(): ✅ Applied outline material to draggable linker")
                }
                
                // Apply to both inner and outer payload
                if var innerComponent = workingPayloadInner.components[ModelComponent.self],
                   var outerComponent = workingPayloadOuter.components[ModelComponent.self] {
                    innerComponent.materials = [material]
                    outerComponent.materials = [material]
                    workingPayloadInner.components[ModelComponent.self] = innerComponent
                    workingPayloadOuter.components[ModelComponent.self] = outerComponent
                    os_log(.debug, "ITR..prepareTargetEntities(): ✅ Applied outline material to draggable payload")
                }
            }
            
            // Add sort components for draggable payloads
            if let sortGroup = adcSortGroup {
                let innerSortComponent = ModelSortGroupComponent(group: sortGroup, order: 50)
                workingPayloadInner.components.set(innerSortComponent)
                
                let outerSortComponent = ModelSortGroupComponent(group: sortGroup, order: 60)
                workingPayloadOuter.components.set(outerSortComponent)
                os_log(.debug, "ITR..prepareTargetEntities(): ✅ Added sort components to draggable payloads (inner: 50, outer: 60)")
            }
            
            // Rest stays the same...
            self.workingLinker = workingLinker
            self.workingPayloadInner = workingPayloadInner
            self.workingPayloadOuter = workingPayloadOuter
            workingPayloadOuter.components.set(ADCProximityComponent(minScale: 2.0, maxScale: 15.0, minProximity: 0.15, maxProximity: 0.6))
            workingPayloadInner.components.set(ADCProximityComponent(minScale: 2.0, maxScale: 15.0, minProximity: 0.15, maxProximity: 0.6))
        }
    }
    
    func cleanup() {
        os_log(.debug, "ITR..reset() called")
        
        // Reset dataModel state
        dataModel.selectedADCAntibody = nil
        dataModel.selectedADCLinker = nil
        dataModel.selectedADCPayload = nil
        dataModel.selectedLinkerType = nil
        dataModel.selectedPayloadType = nil
        dataModel.linkersWorkingIndex = 0
        dataModel.payloadsWorkingIndex = 0
        dataModel.placedLinkerCount = 0
        dataModel.placedPayloadCount = 0
        
        // Reset audio
        currentVOController?.stop()
        currentVOController = nil
        popAudioPlaybackController?.stop()
        popAudioPlaybackController = nil
//        audioStorage?.cleanup()
        
        // Reset entities
        mainEntity?.removeFromParent()
        mainViewEntity.removeFromParent()
        antibodyRootEntity?.removeFromParent()
        
        // Remove all components before removing entities
        antibodyEntity?.components.remove(ModelComponent.self)
        antibodyEntity?.components.remove(CollisionComponent.self)
        antibodyEntity?.components.remove(InputTargetComponent.self)
        
        // Clear all entities
        mainEntity = nil
        mainViewEntity = Entity()
        antibodyRootEntity = nil
        antibodyEntity = nil
        linkerEntity = nil
        payloadEntity = nil
        
        // Clear working entities
        workingLinker = nil
        workingPayloadInner = nil
        workingPayloadOuter = nil
        
        // Clear arrays
        adcLinkers.removeAll(keepingCapacity: false)
        adcPayloadsInner.removeAll(keepingCapacity: false)
        adcPayloadsOuter.removeAll(keepingCapacity: false)
        
        // Clear attachments
        adcAttachmentEntity = nil
        linkerAttachmentEntity = nil
        payloadAttachmentEntity = nil
        
        // Reset flags
        shouldAddADCAttachment = false
        shouldAddLinkerAttachment = false
        shouldAddPayloadAttachment = false
        shouldAddMainViewAttachment = false
        refreshFlag = false
        bubblePopSound = false
        
        // Reset audio resources
        popAudioFileResource = nil
        vo1Audio = nil
        vo2Audio = nil
        vo3Audio = nil
        vo4Audio = nil
        
        // Ensure cleanup happens on main actor
        Task { @MainActor in
            await Task.yield()
            // Release any strong references
            originalAntibodyMaterial = nil
            originalPayloadInnerMaterial = nil
            originalPayloadOuterMaterial = nil
            outlineMaterial = nil
        }
    }
}
