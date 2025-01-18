import SwiftUI
import RealityKit
import RealityKitContent
import OSLog
import ARKit

struct ADCOptimizedImmersive: View {
    
    @Environment(AppModel.self) var appModel
    @Environment(ADCDataModel.self) var dataModel
    
    @State var mainEntity: Entity?
    @State var mainViewEntity = Entity()
    @State var antibodyRootEntity: Entity?
    @State var antibodyEntity: ModelEntity?
    @State var popAudioEntity: Entity?  // Audio source entity for pop sound
    @State var voiceOverAudioEntity: Entity?  // Audio source entity for voice-overs
    
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
    
    @State var vo1Audio: AudioFileResource?
    @State var vo2Audio: AudioFileResource?
    @State var vo3Audio: AudioFileResource?
    @State var vo4Audio: AudioFileResource?
    
    @State var audioEntity: Entity = Entity()
    @State var currentVOController: AudioPlaybackController?
    
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
    
    @State var targetLinkerEntity: Entity?
    @State var targetPayloadEntity: Entity?
    
    var body: some View {
        RealityView { content, attachments in
        let contentRef = content
            Task { @MainActor in
                reset()

                let masterEntity = Entity()
                self.mainEntity = masterEntity
                masterEntity.components.set(PositioningComponent(
                    offsetX: 0.125,
                    offsetY: 0,
                    offsetZ: -1.0
                ))
                masterEntity.name = "MainEntity"
                contentRef.add(masterEntity)
                
                os_log(.debug, "ITR..MainEntity initial position: %@", String(describing: masterEntity.position))
                
                // Load materials and entities
                await setupEntitiesAndMaterials()
                
                setupAttachments(attachments: attachments)
                
                // Now that attachments are set up, prepare audio
                await prepareAudioEntities()
                
                // Play initial VO immediately after preparing audio
                playSpatialAudio(step: 0)
                
                shouldAddADCAttachment = true
                shouldAddMainViewAttachment = true
                
                antibodyRootEntity?.isEnabled = true
                antibodyEntity?.isEnabled = true
                dataModel.adcBuildStep = 0
            }
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
        .onDisappear {
            mainEntity?.removeFromParent()
            mainEntity = nil
        }
        .task {
            await appModel.trackingManager.processWorldTrackingUpdates()
        }
        .task {
            await appModel.trackingManager.monitorTrackingEvents()
        }

        
        .onChange(of: dataModel.adcBuildStep) { oldValue, newValue in
            Task { @MainActor in
                // Log color summary at each step
                os_log(.debug, "ADC Build Step \(newValue) - Color Summary:")
                os_log(.debug, "- Antibody Color: \(dataModel.selectedADCAntibody ?? -1)")
                os_log(.debug, "- Linker Color: \(dataModel.selectedLinkerType ?? -1)")
                os_log(.debug, "- Payload Color: \(dataModel.selectedPayloadType ?? -1)")
                
                // Play step audio
                playSpatialAudio(step: newValue)
                
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
                            // Play pop sound for successful placement
                            bubblePopSound.toggle()
                            
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
                            // Play pop sound for successful placement
                            bubblePopSound.toggle()
                            
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
        .onChange(of: bubblePopSound) { oldValue, newValue in
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
    
    private func setupEntitiesAndMaterials() async {
        // Get outline material
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
        
        // Get antibody scene from asset manager
        guard let antibodyScene = await appModel.assetLoadingManager.instantiateEntity("antibody_scene") else {
            return
        }
        
        self.antibodyRootEntity = antibodyScene
            
        prepareAntibodyEntities()
            
        await prepareLinkerEntities()
        await preparePayloadEntities()
        if let rootEntity = antibodyRootEntity {
            prepareTargetEntities(antibodyScene: rootEntity)
        }
        
        // Ensure linkers start disabled
        self.adcLinkers.forEach { $0.isEnabled = false }
    }
}