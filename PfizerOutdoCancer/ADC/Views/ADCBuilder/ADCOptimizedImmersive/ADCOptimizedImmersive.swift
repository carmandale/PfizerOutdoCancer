import SwiftUI
import RealityKit
import RealityKitContent
import OSLog

struct ADCOptimizedImmersive: View {
    /// The root for the head anchor.
    let headAnchorRoot: Entity = Entity()
    /// The root for the entities in the head-anchored scene.
    let headPositionedEntitiesRoot: Entity = Entity()

    let headPositioner: Entity = Entity()


    @Environment(ADCAppModel.self) var appModel
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
    
    let antibodyAttachmentOffset: SIMD3<Float> = SIMD3(-0.45, 0, 0)
    let linkerAttachmentOffset: SIMD3<Float> = SIMD3(0.35, 0, 0)
    let payloadAttachmentOffset: SIMD3<Float> = SIMD3(0.35, 0, 0)
    let defaultZPosition: Float = -1.0
    let antibodyRootOffset: SIMD3<Float> = SIMD3(0, 0, -1.0)
    
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    
    @State var originalLinkerMaterial: PhysicallyBasedMaterial?
    @State var originalPayloadInnerMaterial: PhysicallyBasedMaterial?
    @State var originalPayloadOuterMaterial: ShaderGraphMaterial?
    
    @State var initialLinkerPosition: SIMD3<Float>?
    @State var initialPayloadPosition: SIMD3<Float>?
    
    var body: some View {
        RealityView { content, attachments in
            reset()
            
            let masterEntity = Entity()
            self.mainEntity = masterEntity
            self.mainEntity?.name = "MainEntity"
            // content.add(masterEntity)
            
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
            
            if dataModel.selectedADCAntibody == nil {
                dataModel.selectedADCAntibody = 0
            }
  
            setupAttachments(attachments: attachments)

            shouldAddADCAttachment = true
            shouldAddMainViewAttachment = true
            
            antibodyRootEntity?.isEnabled = true
            antibodyEntity?.isEnabled = true
            dataModel.adcBuildStep = 0

            /// Head positioning

                
            // MARK: - Load the headPositioner and use `AnchorEntity` to position it.
            // Load the headPositioner.
            headPositioner.addChild(masterEntity)
            
            // Add the head-anchor root. Later, you add `AnchorEntity` to this.
            content.add(headAnchorRoot)
            
            // Show the hummingbird and headPositioner using `AnchorEntity`.
            startHeadPositionMode(content: content)
            
        } update: { content, attachments in
            // updateADC()
            
            
        } attachments: {
            Attachment(id: ADCUIAttachments.mainADCView) {
                ADCBuilderView()
//                ContentView()
            }
        }
        .installGestures()
        .onChange(of: dataModel.adcBuildStep) { oldValue, newValue in
            Task { @MainActor in
                switch newValue {
                case 0:
                    os_log(.debug, "ITR.. ✅ ADC build step 0")
                    // setAntibodyAttachmentPosition()
                    self.adcLinkers.forEach { $0.isEnabled = false }
                    self.linkerEntity?.isEnabled = false
                    self.linkerAttachmentEntity?.isEnabled = false
                    self.payloadEntity?.isEnabled = false
                case 1:
                    os_log(.debug, "ITR.. ✅ ADC build step 1")
                    self.antibodyRootEntity?.components.remove(ADCGestureComponent.self)
                    for (index, element) in adcLinkers.enumerated() {
                        element.isEnabled = index <= dataModel.linkersWorkingIndex
                        element.components.remove(ADCProximitySourceComponent.self)
                    }
                    adcLinkers[dataModel.linkersWorkingIndex].components.set(ADCProximitySourceComponent())
//                    antibodyRootEntity?.components.remove(ProximitySourceComponent.self)
                    
                    if let linkerEntity = linkerEntity {
                        linkerEntity.isEnabled = true
                    //   linkerEntity.position = calculateTargetLinkerPosition()
//                        linkerEntity.look(at: cameraEntity.scenePosition,
//                                          from: linkerEntity.scenePosition,
//                                          relativeTo: nil,
//                                          forward: .positiveZ)
                    }
                    self.linkerAttachmentEntity?.isEnabled = true
//                    setLinkerAttachmentPosition()
                    
                    self.payloadEntity?.isEnabled = false
                case 2:
                    os_log(.debug, "ITR.. ✅ ADC build step 2")
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
                default:
                    os_log(.debug, "ITR.. ✅ ADC build step \(newValue)")
                    self.linkerEntity?.isEnabled = false
                    self.linkerAttachmentEntity?.isEnabled = false
                    self.payloadEntity?.isEnabled = false
                    antibodyRootEntity?.components.set(createGestureComponent())
                }
            }
        }
        .onChange(of: dataModel.selectedADCAntibody) { oldValue, newValue in
            os_log(.debug, "ITR..onChange(of: selectedADCAntibody): new value: \(newValue ?? -1)")
            handleAntibodyColorChange(newValue: newValue)
        }
        .onChange(of: dataModel.selectedLinkerType) { oldValue, newValue in
            os_log(.debug, "ITR..onChange(of: dataModel.selectedLinkerType): new change selected working linker: \(newValue ?? -1)")
            guard dataModel.adcBuildStep == 1  else {
                os_log(.error, "ITR..onChange(of: dataModel.selectedLinkerType): ❌ Error, got a new value for selectedLinkerType: \(newValue ?? -1) but adcBuildStep is not 1")
                return
            }
            Task { @MainActor in
                if let newValue {
                    // Change all linkers to the same color
                    self.adcLinkers.forEach { linker in
                        linker.updatePBRDiffuseColor(.adc[newValue])
                    }
                    // Also update the working linker
                    if let workingLinker {
                        workingLinker.updatePBRDiffuseColor(.adc[newValue])
                    }
                }
            }
        }
        .onChange(of: dataModel.selectedPayloadType) { oldValue, newValue in
            os_log(.debug, "ITR..onChange(of: dataModel.selectedPayloadType): New change selected working payload: \(newValue ?? -1)")
            guard dataModel.adcBuildStep == 2  else {
                os_log(.error, "ITR..onChange(of: dataModel.selectedPayloadType): ❌ Error, got a new value for selectedPayloadType: \(newValue ?? -1) but adcBuildStep is not 1")
                return
            }
            Task { @MainActor in
                if let newValue {
                    // Change all payloads to the same color
                    for (inner, outer) in zip(adcPayloadsInner, adcPayloadsOuter) {
                        inner.updatePBREmissiveColor(.adcEmissive[newValue])
                        outer.updateShaderGraphColor(parameterName: "glowColor", color: .adc[newValue])
                    }
                    
                    // Also update the working payload
                    if let workingPayloadInner,
                       let workingPayloadOuter {
                        workingPayloadInner.updatePBREmissiveColor(.adcEmissive[newValue])
                        workingPayloadOuter.updateShaderGraphColor(parameterName: "glowColor", color: .adc[newValue])
                    }
                }
            }
        }
        .onChange(of: bubblePopSound) { oldValue , newValue in
            self.popAudioPlaybackController?.play()
        }
        .task {
            dismissWindow(id: ADCUIViews.mainViewID)
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
            
            os_log(.debug, "ITR..handleAntibodyColorChange: Attempting to update color")
            guard var modelComponent = antibodyEntity.components[ModelComponent.self] else {
                os_log(.error, "ITR..handleAntibodyColorChange: ❌ No ModelComponent found")
                return
            }
            
            // Try direct material modification
            if var material = modelComponent.materials.first as? PhysicallyBasedMaterial {
                material.baseColor = .init(tint: UIColor.adc[newValue])
                modelComponent.materials = [material]
                antibodyEntity.components[ModelComponent.self] = modelComponent
                os_log(.debug, "ITR..handleAntibodyColorChange: ✅ Updated material directly with color index \(newValue)")
            } else {
                os_log(.error, "ITR..handleAntibodyColorChange: ❌ Could not cast to PhysicallyBasedMaterial")
            }
        }
    }
}

//#Preview {
//    ADCOptimizedImmersive()
//        .glassBackgroundEffect()
//        .environment(ADCAppModel())
//        .environment(ADCDataModel())
//}
extension ADCOptimizedImmersive {
    /// Sets up the follow mode by removing the headPositioner and adding the hummingbird.
    func startFollowMode() {
        // MARK: Clean up the scene.
        // Find the head anchor in the scene and remove it.
        guard let headAnchor = headAnchorRoot.children.first(where: { $0.name == "headAnchor" }) else { return }
        headAnchorRoot.removeChild(headAnchor)
        
        // Remove the headPositioner from the view.
        headPositioner.removeFromParent()
        
        // MARK: - Create the "follow" scene.
        // Set the position of the root so that the hummingbird flies in from the center.
//        followRoot.setPosition([0, 1, -1], relativeTo: nil)
        
        // Rotate the hummingbird to face over the left shoulder, which faces the person due to the offset.
//        let orientation = simd_quatf(angle: .pi * -0.15, axis: [0, 1, 0]) * simd_quatf(angle: .pi * 0.2, axis: [1, 0, 0])
//        hummingbird.transform.rotation = orientation
        
        // Set the hummingbird as a subentity of its root, and move it to the top-right corner.
//        followRoot.addChild(hummingbird)
//        hummingbird.setPosition([0.4, 0.2, -1], relativeTo: followRoot)
    }
    
    /// Sets up the head-position mode by enabling the headPositioner, creating a head anchor, and adding the hummingbird and headPositioner.
    func startHeadPositionMode(content: RealityViewContent) {
        // Reset the rotation so it aligns with the headPositioner.
        // hummingbird.transform.rotation = simd_quatf()
        
        // Create an anchor for the head and set the tracking mode to `.once`.
        let headAnchor = AnchorEntity(.head)
        headAnchor.anchoring.trackingMode = .once
        headAnchor.name = "headAnchor"
        // Add the `AnchorEntity` to the scene.
        headAnchorRoot.addChild(headAnchor)
        
        // Add the headPositioner as a subentity of the root containing the head-positioned entities.
        headPositionedEntitiesRoot.addChild(headPositioner)
        
        // Add the hummingbird to the root containing the head-positioned entities and set the position to be further away than the headPositioner.
        // headPositionedEntitiesRoot.addChild(hummingbird)
        // hummingbird.setPosition([0, 0, -0.15], relativeTo: headPositionedEntitiesRoot)
        
        // Add the head-positioned entities to the anchor, and set the position to be in front of the wearer.
        headAnchor.addChild(headPositionedEntitiesRoot)
        headPositionedEntitiesRoot.setPosition([0, 0, 0], relativeTo: headAnchor)
    }
    
    /// Switches between the follow and head-position modes depending on the `HeadTrackState` case.
    func toggleHeadPositionModeOrFollowMode(content: RealityViewContent) {
//        switch appModel.headTrackState {
//        case .follow:
//            startFollowMode()
//        case .headPosition:
//            startHeadPositionMode(content: content)
//        }
    }
    
    /// Plays the flying animation repeatedly.
    func playHummingbirdAnimation() {
        // Play the animation.
//        guard let flyAnimation = hummingbird.availableAnimations.first else { return }
//        let repeatedAnimation = flyAnimation.repeat(count: .max)
//        hummingbird.playAnimation(repeatedAnimation, transitionDuration: 1, startsPaused: false)
    }
}
