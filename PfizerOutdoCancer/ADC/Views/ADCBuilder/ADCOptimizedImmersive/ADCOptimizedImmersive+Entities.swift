import SwiftUI
import RealityKit
import RealityKitContent
import OSLog


extension ADCOptimizedImmersive {
    func prepareAntibodyEntities() {
        guard let antibodyRoot = antibodyRootEntity else { return }
        
        if let antibody = antibodyRoot.findModelEntity(named: "ADC_complex") {
            self.antibodyEntity = antibody
            antibody.isEnabled = false
            
            // antibodyRoot.scale *= 2
            self.mainEntity?.addChild(antibodyRoot)
            
            // Set initial position
            antibodyRoot.position = antibodyRoot.position + antibodyRootOffset
            
            // Add mainViewEntity as child of antibodyRoot
            mainViewEntity.position = mainViewEntity.position + antibodyAttachmentOffset  // 0.5 meters to the left
            antibodyRoot.addChild(mainViewEntity)
            
            // Keep existing components
//            let billboard = ADCBillboardComponent(offset: [0,-0.2,-0.6],
//                                               axisToFollow: [0,1,0],
//                                               initializePositionOnlyOnce: true,
//                                               isBillboardEnabled: false)
            // antibodyRoot.components.set(billboard)
            antibodyRoot.components.set(createGestureComponent())
            
            // Keep existing orientation
            // let angleDegrees: Float = 30
            // let angleRadians: Float = angleDegrees * (.pi / 180)
            // antibodyRoot.orientation = simd_quatf(angle: angleRadians, axis: [0, 0, 1]) * antibodyRoot.orientation
            
            // Keep audio setup
            if let resource = popAudioFileResource {
                self.popAudioPlaybackController = popAudioEntity?.prepareAudio(resource)
            }
            
            // Store original material
            if let originalMaterial = antibody.components[ModelComponent.self]?.materials.first as? ShaderGraphMaterial {
                self.originalAntibodyMaterial = originalMaterial
                os_log(.debug, "ITR..prepareAntibodyEntities(): ✅ Stored original antibody material")
            }
            
            // Apply outline material
            if let material = outlineMaterial {
                if var modelComponent = antibody.components[ModelComponent.self] {
                    modelComponent.materials = [material]
                    antibody.components[ModelComponent.self] = modelComponent
                    os_log(.debug, "ITR..prepareAntibodyEntities(): ✅ Applied outline material to antibody")
                }
            }
            
            os_log(.info, "ITR..prepareAntibodyEntities(): found all ModelEntities")
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
                }
            } else {
                os_log(.error, "ITR..prepareLinkerEntities(): ❌ No outline material available")
            }
        }
    }
    
    func preparePayloadEntities() async {
        guard let antibodyRoot = antibodyRootEntity else { return }
        if let payload0 = antibodyRoot.findModelEntity(named: "InnerSphere", from: "linker01_offset"),
           let payload1 = antibodyRoot.findModelEntity(named: "InnerSphere", from: "linker02_offset"),
           let payload2 = antibodyRoot.findModelEntity(named: "InnerSphere", from: "linker03_offset"),
           let payload3 = antibodyRoot.findModelEntity(named: "InnerSphere", from: "linker04_offset"),
           let payloadOuter0 = antibodyRoot.findModelEntity(named: "OuterSphere", from: "linker01_offset"),
           let payloadOuter1 = antibodyRoot.findModelEntity(named: "OuterSphere", from: "linker02_offset"),
           let payloadOuter2 = antibodyRoot.findModelEntity(named: "OuterSphere", from: "linker03_offset"),
           let payloadOuter3 = antibodyRoot.findModelEntity(named: "OuterSphere", from: "linker04_offset") {
            
            self.adcPayloadsInner = [payload0, payload1, payload2, payload3]
            self.adcPayloadsOuter = [payloadOuter0, payloadOuter1, payloadOuter2, payloadOuter3]
            
            // Store original materials
            if let innerMaterial = payload0.components[ModelComponent.self]?.materials.first as? PhysicallyBasedMaterial {
                self.originalPayloadInnerMaterial = innerMaterial
                os_log(.debug, "ITR..preparePayloadEntities(): ✅ Stored original inner PBR material")
            }
            
            if let outerMaterial = payloadOuter0.components[ModelComponent.self]?.materials.first as? ShaderGraphMaterial {
                self.originalPayloadOuterMaterial = outerMaterial
                os_log(.debug, "ITR..preparePayloadEntities(): ✅ Stored original outer shader material")
            }
            
            // Apply stored outline material to all payloads
            if let material = outlineMaterial {
                // Apply to inner payloads
                self.adcPayloadsInner.forEach { payload in
                    if var modelComponent = payload.components[ModelComponent.self] {
                        modelComponent.materials = [material]
                        payload.components[ModelComponent.self] = modelComponent
                        payload.isEnabled = false
                    }
                }
                
                // Apply to outer payloads
                self.adcPayloadsOuter.forEach { payload in
                    if var modelComponent = payload.components[ModelComponent.self] {
                        modelComponent.materials = [material]
                        payload.components[ModelComponent.self] = modelComponent
                        payload.isEnabled = false
                    }
                }
            } else {
                os_log(.error, "ITR..preparePayloadEntities(): ❌ No outline material available")
            }
            
            os_log(.info, "ITR..preparePayloadEntities(): found all ModelEntities")

        } else {
            os_log(.error, "ITR..preparePayloadEntities(): ❌ Error, not all ModelEntities found")
        }
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
            workingLinker.components.set(ADCProximityComponent(minScale: 0.2, maxScale: 1.0, minProximity: 0.1, maxProximity: 0.5))
            
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
            
            // Rest stays the same...
            self.workingLinker = workingLinker
            self.workingPayloadInner = workingPayloadInner
            self.workingPayloadOuter = workingPayloadOuter
            workingPayloadOuter.components.set(ADCProximityComponent(minScale: 2.0, maxScale: 15.0, minProximity: 0.15, maxProximity: 0.6))
            workingPayloadInner.components.set(ADCProximityComponent(minScale: 2.0, maxScale: 15.0, minProximity: 0.15, maxProximity: 0.6))
        }
    }
}
