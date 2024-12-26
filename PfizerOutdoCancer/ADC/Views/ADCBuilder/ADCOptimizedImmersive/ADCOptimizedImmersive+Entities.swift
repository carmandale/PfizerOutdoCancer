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
                self.popAudioPlaybackController = antibody.prepareAudio(resource)
            }
            
            os_log(.info, "ITR..prepareAntibodyEntities(): found all ModelEntities")
        }
    }
    
    
    func prepareLinkerEntities() async {
        guard let antibodyRoot = antibodyRootEntity else { return }
        
        if let linker0 = antibodyRoot.findModelEntity(named: "linker", from: "linker01_offset"),
           let linker1 = antibodyRoot.findModelEntity(named: "linker", from: "linker02_offset"),
           let linker2 = antibodyRoot.findModelEntity(named: "linker", from: "linker03_offset"),
           let linker3 = antibodyRoot.findModelEntity(named: "linker", from: "linker04_offset"){
            
            self.adcLinkers = [linker0, linker1, linker2, linker3]
            
            // Store original material from first linker
            if let originalMaterial = linker0.components[ModelComponent.self]?.materials.first as? PhysicallyBasedMaterial {
                self.originalLinkerMaterial = originalMaterial
                os_log(.debug, "ITR..prepareLinkerEntities(): ✅ Stored original PBR material")
            } else {
                os_log(.error, "ITR..prepareLinkerEntities(): ❌ Could not get original PBR material")
            }
            
            // Load outline material and apply...
            os_log(.debug, "ITR..prepareLinkerEntities(): Attempting to load M_outline material from Materials/M_outline.usda")
            do {
                let materialEntity = try await Entity(named: "Materials/M_outline.usda", in: realityKitContentBundle)
                os_log(.debug, "ITR..prepareLinkerEntities(): ✅ Successfully loaded material entity")
                
                if let sphereEntity = materialEntity.findEntity(named: "Sphere") {
                    os_log(.debug, "ITR..prepareLinkerEntities(): Found Root entity")
                    
                    let components = sphereEntity.components
                    guard let modelComponent = components[ModelComponent.self] else { fatalError("Model entity is required.") }

                    // Try to get material directly from Root's materials
                    if let material = modelComponent.materials.first as? ShaderGraphMaterial {
                        os_log(.debug, "ITR..prepareLinkerEntities(): ✅ Found M_outline material from Root")
                        
                        self.adcLinkers.forEach { linker in
                            if var modelComponent = linker.components[ModelComponent.self] {
                                os_log(.debug, "ITR..prepareLinkerEntities(): Applying outline material to linker")
                                modelComponent.materials = [material]
                                linker.components[ModelComponent.self] = modelComponent
                                linker.isEnabled = false
                            }
                        }
                    } else {
                        os_log(.error, "ITR..prepareLinkerEntities(): ❌ Could not find material in Root")
                    }
                } else {
                    os_log(.error, "ITR..prepareLinkerEntities(): ❌ Could not find Root entity")
                }
            } catch {
                os_log(.error, "ITR..prepareLinkerEntities(): ❌ Failed to load M_outline material: \(error)")
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
           let payloadOuter3 = antibodyRoot.findModelEntity(named: "OuterSphere", from: "linker04_offset"){
            
            self.adcPayloadsInner = [payload0, payload1, payload2, payload3]
            os_log(.debug, "ITR..preparePayloadEntities(): Found OuterSphere: \(String(describing: payloadOuter0))")
            os_log(.debug, "ITR..preparePayloadEntities(): OuterSphere materials: \(payloadOuter0.model?.materials ?? [])")
            
            // Debug the OuterSphere entity structure
            os_log(.debug, "ITR..preparePayloadEntities(): Inspecting OuterSphere entity:")
            AssetLoadingManager.shared.inspectEntityHierarchy(payloadOuter0)
            
            self.adcPayloadsOuter = [payloadOuter0, payloadOuter1, payloadOuter2, payloadOuter3]
            
            // Store original materials first
            guard let innerMaterial = payload0.components[ModelComponent.self]?.materials.first as? PhysicallyBasedMaterial else {
                os_log(.error, "ITR..preparePayloadEntities(): ❌ Could not get original PBR material")
                return
            }
            self.originalPayloadInnerMaterial = innerMaterial
            os_log(.debug, "ITR..preparePayloadEntities(): ✅ Stored original inner PBR material")
            
            guard let outerMaterial = payloadOuter0.components[ModelComponent.self]?.materials.first as? ShaderGraphMaterial else {
                os_log(.error, "ITR..preparePayloadEntities(): ❌ Could not get ShaderGraphMaterial")
                return
            }
            os_log(.debug, "ITR..preparePayloadEntities(): Found outer shader material: \(String(describing: outerMaterial))")
            os_log(.debug, "ITR..preparePayloadEntities(): Available parameters: \(String(describing: outerMaterial.parameterNames))")
            os_log(.debug, "ITR..preparePayloadEntities(): Material name: \(String(describing: outerMaterial.name))")
            self.originalPayloadOuterMaterial = outerMaterial
            os_log(.debug, "ITR..preparePayloadEntities(): ✅ Stored original outer shader material")
            
            // Apply outline material to both spheres
            do {
                let materialEntity = try await Entity(named: "Materials/M_outline.usda", in: realityKitContentBundle)
                if let outlineMaterial = materialEntity.findEntity(named: "Sphere")?.components[ModelComponent.self]?.materials.first {
                    // Apply to inner payloads
                    self.adcPayloadsInner.forEach { payload in
                        if var modelComponent = payload.components[ModelComponent.self] {
                            modelComponent.materials = [outlineMaterial]
                            payload.components[ModelComponent.self] = modelComponent
                            payload.isEnabled = false
                        }
                    }
                    
                    // Apply to outer payloads
                    self.adcPayloadsOuter.forEach { payload in
                        if var modelComponent = payload.components[ModelComponent.self] {
                            modelComponent.materials = [outlineMaterial]
                            payload.components[ModelComponent.self] = modelComponent
                            payload.isEnabled = false
                        }
                    }
                }
            } catch {
                os_log(.error, "ITR..preparePayloadEntities(): ❌ Failed to load outline material: \(error)")
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
            
            // Rest stays the same...
            self.workingLinker = workingLinker
            self.workingPayloadInner = workingPayloadInner
            self.workingPayloadOuter = workingPayloadOuter
            workingPayloadOuter.components.set(ADCProximityComponent(minScale: 2.0, maxScale: 15.0, minProximity: 0.15, maxProximity: 0.6))
            workingPayloadInner.components.set(ADCProximityComponent(minScale: 2.0, maxScale: 15.0, minProximity: 0.15, maxProximity: 0.6))
        }
    }
}