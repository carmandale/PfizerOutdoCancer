import SwiftUI
import RealityKit
import RealityKitContent
import OSLog
import ARKit

struct ADCOptimizedImmersive: View {
    // /// The root for the head anchor.
    // let headAnchorRoot: Entity = Entity()
    // /// The root for the entities in the head-anchored scene.
    // let headPositionedEntitiesRoot: Entity = Entity()

    // let headPositioner: Entity = Entity()

    // // ARKitSession and WorldTrackingProvider
    // let arSession = ARKitSession()
    // let worldTracking = WorldTrackingProvider()

    @State private var headTracker = HeadPositionTracker()


    @Environment(AppModel.self) var appModel
    @Environment(ADCDataModel.self) var dataModel
    
    @State var mainEntity: Entity? = nil
    @State var cameraEntity: RealityKit.Entity = .init()
    @State var mainViewEntity: RealityKit.Entity = .init()
    
    @State var antibodyRootEntity: Entity?
    
    @State var antibodyEntity: ModelEntity?
    @State var linkerEntity: Entity?
    @State var payloadEntity: Entity?
    
    @State var workingLinker: ModelEntity?
    @State var workingPayloadInner: ModelEntity?
    @State var workingPayloadOuter: ModelEntity?

    @State var adcLinkers: [ModelEntity] = .init()
    @State var adcPayloadsInner: [ModelEntity] = .init()
    @State var adcPayloadsOuter: [ModelEntity] = .init()

    @State var adcAttachmentEntity: ViewAttachmentEntity?
    @State var linkerAttachmentEntity: ViewAttachmentEntity?
    @State var payloadAttachmentEntity: ViewAttachmentEntity?
    
    @State var shouldAddADCAttachment: Bool = false
    @State var shouldAddLinkerAttachment: Bool = false
    @State var shouldAddPayloadAttachment: Bool = false
    @State var shouldAddMainViewAttachment: Bool = false
    
    @State var refreshFlag = false
    @State var bubblePopSound = false
    
    @State var popAudioFileResource: AudioFileResource?
    @State var popAudioPlaybackController: AudioPlaybackController?
    
    @State var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State var isCameraInitialized = false
    
    let antibodyAttachmentOffset: SIMD3<Float> = SIMD3(-0.5, 0, 0)
    let linkerAttachmentOffset: SIMD3<Float> = SIMD3(0.35, 0, 0)
    let payloadAttachmentOffset: SIMD3<Float> = SIMD3(0.35, 0, 0)
    let defaultZPosition: Float = -1.0
    let antibodyRootOffset: SIMD3<Float> = SIMD3(0, 0, 0)
    
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    
    @State var originalLinkerMaterial: ShaderGraphMaterial?
    @State var originalPayloadInnerMaterial: PhysicallyBasedMaterial?
    @State var originalPayloadOuterMaterial: ShaderGraphMaterial?
    
    @State var initialLinkerPosition: SIMD3<Float>?
    @State var initialPayloadPosition: SIMD3<Float>?
    
    @State var outlineMaterial: ShaderGraphMaterial?
    
    @State var originalAntibodyMaterial: ShaderGraphMaterial?

    private func positionMainEntity() {
        headTracker.positionEntityRelativeToUser(mainEntity, offset: [0.125, 0, -1.0])
    }
    
    var body: some View {
        RealityView { content, attachments in
        // start the arkit session
            Task {
                try? await headTracker.ensureInitialized()
            }
            reset()
            
            // Load outline material first
            do {
                let materialEntity = try await Entity(named: "Materials/M_outline.usda", in: realityKitContentBundle)
                if let sphereEntity = materialEntity.findEntity(named: "Sphere"),
                   let material = sphereEntity.components[ModelComponent.self]?.materials.first as? ShaderGraphMaterial {
                    os_log(.debug, "ITR..RealityView(): ✅ Successfully loaded outline material")
                    self.outlineMaterial = material
                }
            } catch {
                os_log(.error, "ITR..RealityView(): ❌ Failed to load outline material: \(error)")
            }
            
            let masterEntity = Entity()
            self.mainEntity = masterEntity
            self.mainEntity?.name = "MainEntity"
            content.add(masterEntity)
            
            if let antibodyScene = try? await Entity(named: "antibodyScene", in: realityKitContentBundle),
               let antibodyRoot = antibodyScene.findEntity(named: "antibodyProtein_complex_assembled"){

                if let resource = try? await AudioFileResource(named:"/Root/bubblepop_mp3", from: "antibodyScene.usda", in: realityKitContentBundle) {
                    popAudioFileResource = resource
                } else {
                    os_log(.error, "ITR..ADCOptimizedImmersive.RealityView(): ❌ Error, couldn't find Audio in antibodyScene.usda")
                }

                self.antibodyRootEntity = antibodyRoot
                prepareAntibodyEntities()
                await prepareLinkerEntities()
                await preparePayloadEntities()
                prepareTargetEntities(antibodyScene: antibodyScene)
                
                // Ensure linkers start disabled
                self.adcLinkers.forEach { $0.isEnabled = false }
                
                antibodyRootEntity?.isEnabled = true
                antibodyEntity?.isEnabled = true
                dataModel.adcBuildStep = 0
            } else {
                os_log(.error, "ITR..ADCOptimizedImmersive.RealityView(): ❌ Error, couldn't find Entity from RealityKitContent")
            }
            
            setupAttachments(attachments: attachments)

            shouldAddADCAttachment = true
            shouldAddMainViewAttachment = true
            
            antibodyRootEntity?.isEnabled = true
            antibodyEntity?.isEnabled = true
            dataModel.adcBuildStep = 0

            /// Head positioning
            positionMainEntity()

            
        } update: { content, attachments in
            // updateADC()
        } attachments: {
            Attachment(id: ADCUIAttachments.mainADCView) {
                ADCBuilderView()
            }
        }
        .installGestures()
        .onAppear {
            dismissWindow(id: AppModel.debugNavigationWindowId)
        }
        .onChange(of: dataModel.adcBuildStep) { oldValue, newValue in
            Task { @MainActor in
                // Log color summary at each step
                os_log(.debug, "ADC Build Step \(newValue) - Color Summary:")
                os_log(.debug, "- Antibody Color: \(dataModel.selectedADCAntibody ?? -1)")
                os_log(.debug, "- Linker Color: \(dataModel.selectedLinkerType ?? -1)")
                os_log(.debug, "- Payload Color: \(dataModel.selectedPayloadType ?? -1)")
                
                switch newValue {
                case 0:
                    // Starting case - select the antibody color
                    os_log(.debug, "ITR.. ✅ ADC build step 0")
                    // setAntibodyAttachmentPosition()
                    self.adcLinkers.forEach { $0.isEnabled = false }
                    self.linkerEntity?.isEnabled = false
                    self.linkerAttachmentEntity?.isEnabled = false
                    self.payloadEntity?.isEnabled = false
                case 1:
                    os_log(.debug, "ITR.. ✅ ADC build step 1 - checkmark to move past antibody to linker")
                    self.antibodyRootEntity?.components.remove(ADCGestureComponent.self)
                    for (index, element) in adcLinkers.enumerated() {
                        element.isEnabled = index <= dataModel.linkersWorkingIndex
                        element.components.remove(ADCProximitySourceComponent.self)
                    }
                    adcLinkers[dataModel.linkersWorkingIndex].components.set(ADCProximitySourceComponent())
                    
                    if let linkerEntity = linkerEntity {
                        linkerEntity.isEnabled = true
                    }
                    self.linkerAttachmentEntity?.isEnabled = true
                    self.payloadEntity?.isEnabled = false
                case 2:
                    // clicked checkmark to apply the material to all of the linkers
                    os_log(.debug, "ITR.. ✅ ADC build step 2 - checkmark to fill all linkers")
                    // If we came from checkmark button (all linkers filled)
                    if dataModel.linkersWorkingIndex == 4 {
                        Task { @MainActor in
                            // Apply original material and selected color to all linkers
                            for linker in adcLinkers {
                                if let originalMaterial = originalLinkerMaterial {
                                    linker.updateMaterials { material in
                                        material = originalMaterial
                                    }
                                }
                                // changed underlying shader to shaderGraph
                                linker.updateShaderGraphColor(parameterName: "Basecolor_Tint", color: .adc[dataModel.selectedLinkerType ?? 0])
                                linker.isEnabled = true
                            }
                        }
                    }
                    
                    self.adcLinkers.forEach { $0.isEnabled = true }
                    self.linkerEntity?.isEnabled = false
                    self.linkerAttachmentEntity?.isEnabled = false
                    self.payloadEntity?.isEnabled = true
                    for (index, element) in adcPayloadsInner.enumerated() {
                        element.isEnabled = index <= dataModel.payloadsWorkingIndex
                    }
                    for (index, element) in adcPayloadsOuter.enumerated() {
                        element.isEnabled = index <= dataModel.payloadsWorkingIndex
                        element.components.remove(ADCProximitySourceComponent.self)
                    }
                    adcPayloadsOuter[dataModel.payloadsWorkingIndex].components.set(ADCProximitySourceComponent())
                case 3:
                    // clicked checkmark to apply the material to all of the payloads
                    os_log(.debug, "ITR.. ✅ ADC build step 3 - checkmark to fill all payloads")
                    // If we came from checkmark button (all payloads filled)
                    if dataModel.payloadsWorkingIndex == 4 {
                        Task { @MainActor in
                            // Apply original materials and selected color to all payloads
                            for (inner, outer) in zip(adcPayloadsInner, adcPayloadsOuter) {
                                if let originalInnerMaterial = originalPayloadInnerMaterial {
                                    inner.updateMaterials { material in
                                        material = originalInnerMaterial
                                    }
                                }
                                if let originalOuterMaterial = originalPayloadOuterMaterial {
                                    outer.model?.materials = [originalOuterMaterial]
                                }

                                inner.updatePBREmissiveColor(.adcEmissive[dataModel.selectedPayloadType ?? 0])
                                outer.updateShaderGraphColor(parameterName: "glowColor", color: .adc[dataModel.selectedPayloadType ?? 0])

                                inner.isEnabled = true
                                outer.isEnabled = true
                            }
                        }
                    }
                    
                    self.linkerEntity?.isEnabled = false
                    self.linkerAttachmentEntity?.isEnabled = false
                    self.payloadEntity?.isEnabled = false
                    antibodyRootEntity?.components.set(createGestureComponent())
                default:
                    os_log(.debug, "ITR.. ✅ ADC build step \(newValue)")
                    self.linkerEntity?.isEnabled = false
                    self.linkerAttachmentEntity?.isEnabled = false
                    self.payloadEntity?.isEnabled = false
                    antibodyRootEntity?.components.set(createGestureComponent())
                }
            }
        }
        // Change the Antibody 3D model material color to the selected color
        .onChange(of: dataModel.selectedADCAntibody) { oldValue, newValue in
            os_log(.debug, "ITR..onChange(of: selectedADCAntibody): new value: \(newValue ?? -1)")
            handleAntibodyColorChange(newValue: newValue)
        }
        // Change the linker 3D model material color to the selected color
        .onChange(of: dataModel.selectedLinkerType) { oldValue, newValue in
            Task { @MainActor in
                if let newValue {
                    // Update working (target) linker first
                    if let workingLinker {
                        // First restore original material
                        if let originalMaterial = originalLinkerMaterial {
                            if var modelComponent = workingLinker.components[ModelComponent.self] {
                                modelComponent.materials = [originalMaterial]
                                workingLinker.components[ModelComponent.self] = modelComponent
                            }
                        }
                        // Then apply color
                        workingLinker.updateShaderGraphColor(parameterName: "Basecolor_Tint", color: .adc[newValue])
                    }
                    
                    // Update all previously placed linkers (up to current working index)
                    for index in 0..<dataModel.linkersWorkingIndex {
                        if let originalMaterial = originalLinkerMaterial {
                            if var modelComponent = adcLinkers[index].components[ModelComponent.self] {
                                modelComponent.materials = [originalMaterial]
                                adcLinkers[index].components[ModelComponent.self] = modelComponent
                            }
                        }
                        adcLinkers[index].updateShaderGraphColor(parameterName: "Basecolor_Tint", color: .adc[newValue])
                    }
                }
            }
        }
        // Change the payload inner and outer 3D model material color to the selected color
        .onChange(of: dataModel.selectedPayloadType) { oldValue, newValue in
            os_log(.debug, "ITR..onChange(of: dataModel.selectedPayloadType): New change selected working payload: \(newValue ?? -1)")
            guard dataModel.adcBuildStep == 2  else {
                os_log(.error, "ITR..onChange(of: dataModel.selectedPayloadType): ❌ Error, got a new value for selectedPayloadType: \(newValue ?? -1) but adcBuildStep is not 1")
                return
            }
            Task { @MainActor in
                if let newValue {
                    // Update working (target) payload first
                    if let workingPayloadInner,
                       let workingPayloadOuter {
                        // First restore original materials
                        if let originalInnerMaterial = originalPayloadInnerMaterial {
                            if var modelComponent = workingPayloadInner.components[ModelComponent.self] {
                                modelComponent.materials = [originalInnerMaterial]
                                workingPayloadInner.components[ModelComponent.self] = modelComponent
                            }
                        }
                        if let originalOuterMaterial = originalPayloadOuterMaterial {
                            if var modelComponent = workingPayloadOuter.components[ModelComponent.self] {
                                modelComponent.materials = [originalOuterMaterial]
                                workingPayloadOuter.components[ModelComponent.self] = modelComponent
                            }
                        }
                        // Then apply colors
                        workingPayloadInner.updatePBREmissiveColor(.adcEmissive[newValue])
                        workingPayloadOuter.updateShaderGraphColor(parameterName: "glowColor", color: .adc[newValue])
                    }
                    
                    // Change all payloads to the same color
                    for (inner, outer) in zip(adcPayloadsInner, adcPayloadsOuter) {
                        inner.updatePBREmissiveColor(.adcEmissive[newValue])
                        outer.updateShaderGraphColor(parameterName: "glowColor", color: .adc[newValue])
                    }
                }
            }
        }
        .onChange(of: bubblePopSound) { oldValue , newValue in
            self.popAudioPlaybackController?.play()
        }
    }
    
    // MARK: - Preparation
    
    
    func reset() {
        os_log(.debug, "ITR..reset() called")
        dataModel.selectedADCAntibody = nil
        dataModel.selectedADCLinker = nil
        dataModel.selectedADCPayload = nil
        dataModel.selectedLinkerType = nil
        dataModel.selectedPayloadType = nil
        dataModel.linkersWorkingIndex = 0
        dataModel.payloadsWorkingIndex = 0
        dataModel.placedLinkerCount = 0
        dataModel.placedPayloadCount = 0
    }
    
 
    
    private func handleAntibodyColorChange(newValue: Int?) {
        Task { @MainActor in
            guard let newValue = newValue,
                  let antibodyEntity = antibodyEntity else {
                os_log(.error, "ITR..handleAntibodyColorChange: ❌ Missing newValue or antibodyEntity")
                return
            }
            
            if var modelComponent = antibodyEntity.components[ModelComponent.self] {
                // First restore original material
                if let originalMaterial = originalAntibodyMaterial {
                    modelComponent.materials = [originalMaterial]
                    antibodyEntity.components[ModelComponent.self] = modelComponent
                    os_log(.debug, "ITR..handleAntibodyColorChange: ✅ Restored original material")
                }
                
                // Then apply the color
                antibodyEntity.updateShaderGraphColor(parameterName: "Basecolor_Tint", color: .adc[newValue])
                os_log(.debug, "ITR..handleAntibodyColorChange: ✅ Applied color \(newValue)")
            }
        }
    }
}


// extension ADCOptimizedImmersive {

//     private func setupWorldTracking() {
//     Task {
//         guard WorldTrackingProvider.isSupported else {
//             os_log(.error, "WorldTrackingProvider not supported")
//             return
//         }
        
//         do {
//             try await arSession.run([worldTracking])
//         } catch {
//             os_log(.error, "Failed to start world tracking: %@", error.localizedDescription)
//         }
//     }
// }
    
//     /// Sets up the head-position mode by enabling the headPositioner, creating a head anchor, and adding the hummingbird and headPositioner.
//     func startHeadPositionMode(content: RealityViewContent) {
//         // setupWorldTracking()
//         // Create head anchor that only tracks position
//         let headAnchor = AnchorEntity(.head)
//         headAnchor.name = "headAnchor"
        
//         // Critical: Set tracking to once so it doesn't continuously follow head
//         headAnchor.anchoring.trackingMode = .once

//         // Log the device transform before setting up hierarchy
//         if let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) {
//             let deviceTransform = deviceAnchor.originFromAnchorTransform
//             os_log(.debug, "ITR..Device Transform: \n%.3f, %.3f, %.3f, %.3f\n%.3f, %.3f, %.3f, %.3f\n%.3f, %.3f, %.3f, %.3f\n%.3f, %.3f, %.3f, %.3f",
//                 deviceTransform.columns.0.x, deviceTransform.columns.1.x, deviceTransform.columns.2.x, deviceTransform.columns.3.x,
//                 deviceTransform.columns.0.y, deviceTransform.columns.1.y, deviceTransform.columns.2.y, deviceTransform.columns.3.y,
//                 deviceTransform.columns.0.z, deviceTransform.columns.1.z, deviceTransform.columns.2.z, deviceTransform.columns.3.z,
//                 deviceTransform.columns.0.w, deviceTransform.columns.1.w, deviceTransform.columns.2.w, deviceTransform.columns.3.w)
//         }
        
//         // Maintain proper entity hierarchy
//         headPositionedEntitiesRoot.addChild(headPositioner)
//         headAnchor.addChild(headPositionedEntitiesRoot)
//         headAnchorRoot.addChild(headAnchor)
        
//         // Set initial position relative to head anchor
//         headPositionedEntitiesRoot.setPosition([0, 0, 0], relativeTo: headAnchor)
        
//         // 2. After a tiny delay or next frame, flatten out pitch & roll at the child level
//             Task { @MainActor in
//                 // Let RealityKit finalize the anchor
//                 try? await Task.sleep(nanoseconds: 100_000_000) // Increased to 100ms

//                 // Log world transform to see if we're getting any rotation at all
//                 let worldTransform = headAnchor.transformMatrix(relativeTo: nil)
//                 os_log(.debug, "ITR..Head Anchor World Transform: \n%.3f, %.3f, %.3f, %.3f\n%.3f, %.3f, %.3f, %.3f\n%.3f, %.3f, %.3f, %.3f\n%.3f, %.3f, %.3f, %.3f",
//                        worldTransform.columns.0.x, worldTransform.columns.1.x, worldTransform.columns.2.x, worldTransform.columns.3.x,
//                        worldTransform.columns.0.y, worldTransform.columns.1.y, worldTransform.columns.2.y, worldTransform.columns.3.y,
//                        worldTransform.columns.0.z, worldTransform.columns.1.z, worldTransform.columns.2.z, worldTransform.columns.3.z,
//                        worldTransform.columns.0.w, worldTransform.columns.1.w, worldTransform.columns.2.w, worldTransform.columns.3.w)

//                 let anchorRotation = headAnchor.transform.rotation
//                 os_log(.debug, "ITR..Head Anchor Original Rotation - ix: %.3f, iy: %.3f, iz: %.3f, r: %.3f", 
//                        anchorRotation.imag.x, anchorRotation.imag.y, anchorRotation.imag.z, anchorRotation.real)
                
//                 // Verify tracking mode
//                 os_log(.debug, "ITR..Head Anchor Tracking Mode: %@", String(describing: headAnchor.anchoring.trackingMode))
                
//                 let anchorEuler = anchorRotation.toEulerAngles()
//                 os_log(.debug, "ITR..Euler Angles - pitch: %.3f, yaw: %.3f, roll: %.3f", 
//                        anchorEuler.x, anchorEuler.y, anchorEuler.z)
                
//                 let pitchRollOnly = simd_quatf(fromEuler: [anchorEuler.x, 0, anchorEuler.z])
//                 os_log(.debug, "ITR..Pitch/Roll Only Quaternion - ix: %.3f, iy: %.3f, iz: %.3f, r: %.3f", 
//                        pitchRollOnly.imag.x, pitchRollOnly.imag.y, pitchRollOnly.imag.z, pitchRollOnly.real)
                
//                 let cancelPitchRoll = simd_inverse(pitchRollOnly)
//                 os_log(.debug, "ITR..Inverse Pitch/Roll Quaternion - ix: %.3f, iy: %.3f, iz: %.3f, r: %.3f", 
//                        cancelPitchRoll.imag.x, cancelPitchRoll.imag.y, cancelPitchRoll.imag.z, cancelPitchRoll.real)
                
//                 let currentRotation = headPositioner.transform.rotation
//                 os_log(.debug, "ITR..Head Positioner Current Rotation - ix: %.3f, iy: %.3f, iz: %.3f, r: %.3f", 
//                        currentRotation.imag.x, currentRotation.imag.y, currentRotation.imag.z, currentRotation.real)
                
//                 headPositioner.transform.rotation = cancelPitchRoll
                
//                 let finalRotation = headPositioner.transform.rotation
//                 os_log(.debug, "ITR..Head Positioner Final Rotation - ix: %.3f, iy: %.3f, iz: %.3f, r: %.3f", 
//                        finalRotation.imag.x, finalRotation.imag.y, finalRotation.imag.z, finalRotation.real)
//             }
//     }
// }
