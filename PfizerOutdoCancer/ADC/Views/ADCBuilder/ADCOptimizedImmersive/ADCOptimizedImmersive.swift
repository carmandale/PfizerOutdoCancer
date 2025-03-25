// ADCOptimizedImmersive.swift
//
//  ADCOptimizedImmersive
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 1/4/25.
//
//  This file contains the ADCImmersiveView, which is the immersive view
//  for the ADC Builder.  This view contains the main view hierarchy of the
//  ADC Builder, including the main view, the ADC attachment, and the
//  linker and payload attachment entities.


import SwiftUI
import RealityKit
import RealityKitContent
import OSLog
import ARKit

// MARK: - Types

enum ADCEntityType {
    case linker
    case payload
}

struct ADCOptimizedImmersive: View {
    
    @Environment(AppModel.self) var appModel
    @Environment(ADCDataModel.self) var dataModel
    
    // Audio system
    @State internal var bubblePopSound = false
    
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
    
    // Sort group for managing render order of ADC components
    @State var adcSortGroup: ModelSortGroup?
    
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
    
    @State var popAudioFileResource: AudioFileResource?
    @State var audioEntity: Entity = Entity()
    @State var currentVOController: AudioPlaybackController?
    @State var popAudioPlaybackController: AudioPlaybackController?
    
    @State var vo1Audio: AudioFileResource?
    @State var vo2Audio: AudioFileResource?
    @State var vo3Audio: AudioFileResource?
    @State var vo4Audio: AudioFileResource?
    @State var completionAudio: AudioFileResource?
    @State var niceJobAudio: AudioFileResource?
    
    @State var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State var isCameraInitialized = false

    @State var useChannelAudioForVO: Bool = true
    
    // let antibodyAttachmentOffset: SIMD3<Float> = SIMD3(-0.5, 0, 0)
    let linkerAttachmentOffset: SIMD3<Float> = SIMD3(0.25, 0, 0)
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
            let root = dataModel.setupRoot()
            mainEntity = root
            content.add(root)
            
            Task { @MainActor in
                await setupEntitiesAndMaterials(in: root)
                setupAttachments(attachments: attachments)
                await prepareAudioEntities()
                dataModel.isEnvironmentSetupComplete = true
                dataModel.shouldUpdateHeadPosition = true
            }
        } update: { content, attachments in
            // updateADC()
        } attachments: {
            Attachment(id: ADCUIAttachments.mainADCView) {
                ADCBuilderView()
            }
            Attachment(id: ADCUIAttachments.coachingOverlay) {
                ADCcoaching()
                    .opacity(dataModel.isCoachingOverlayPresent ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: dataModel.isCoachingOverlayPresent)
            }
        }
        .installGestures()
        .onAppear {
            dismissWindow(id: AppModel.navWindowId)
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
        // Position update handler
        .onChange(of: dataModel.shouldUpdateHeadPosition) { _, shouldUpdate in
            if shouldUpdate && dataModel.isReadyForInteraction {
                if let root = mainEntity {
                    Logger.info("""
                    
                    🎯 Head Position Update Requested
                    ├─ Current World Position: \(root.position(relativeTo: nil))
                    ├─ Root Setup: \(dataModel.isRootSetupComplete ? "✅" : "❌")
                    ├─ Environment: \(dataModel.isEnvironmentSetupComplete ? "✅" : "❌")
                    └─ HeadTracking: \(dataModel.isHeadTrackingRootReady ? "✅" : "❌")
                    """)
                    
                    Task {
                        root.checkHeadPosition(animated: true, duration: 0.5)
                        dataModel.shouldUpdateHeadPosition = false
                        dataModel.isPositioningComplete = true  // Set after animation completes
                    }
                }
            }
        }
        // Setup continuation handler
        .onChange(of: dataModel.isPositioningComplete) { _, complete in
            if complete {
                Task { @MainActor in
                    
                    
                    shouldAddADCAttachment = true
                    shouldAddMainViewAttachment = true
                    
                    antibodyRootEntity?.isEnabled = true
                    antibodyEntity?.isEnabled = false
                    antibodyEntity?.opacity = 0
                    dataModel.adcBuildStep = 0

                    dataModel.showMainView = true
                    
                    // Play audio for initial step
                    do {
                        try await playVoiceOver(step: 0)
                    } catch {
                        os_log(.error, "ITR..ADCOptimizedImmersive: ❌ Failed to play initial VO: \(error)")
                    }
                }
            }
        }
        .onChange(of: appModel.currentPhase) { oldPhase, newPhase in
            if oldPhase == .building && newPhase != .building {
                print("\n=== ADCOptimizedImmersive Phase Change ===")
                print("Transitioning from .building to \(newPhase)")
                // Cleanup is now handled by AppModel
                print("✅ ADCOptimizedImmersive phase change complete\n")
            }
        }
        // MARK: Build Step
        .onChange(of: dataModel.adcBuildStep) { oldValue, newValue in
            Task { @MainActor in
                // Log color summary at each step
                os_log(.debug, "ADC Build Step \(newValue) - Color Summary:")
                os_log(.debug, "- Antibody Color: \(dataModel.selectedADCAntibody ?? -1)")
                os_log(.debug, "- Linker Color: \(dataModel.selectedLinkerType ?? -1)")
                os_log(.debug, "- Payload Color: \(dataModel.selectedPayloadType ?? -1)")
                
                // Play step audio only if this is a natural transition
                if !dataModel.manualStepTransition {
                    Task { @MainActor in
                        do {
                            try await playVoiceOver(step: newValue)
                        } catch {
                            os_log(.error, "ITR..createLinkerGestureComponent(): ❌ Failed to play VO: \(error)")
                        }
                    }
                }
//                else {
//                    // Reset manual flag for future transitions
//                    dataModel.manualStepTransition = false
//                }
                
                switch newValue {
                case 0:
                    // Starting case - select the antibody color
                    os_log(.debug, "ITR.. ✅ ADC build step 0")
                    // setAntibodyAttachmentPosition()
//                    self.adcLinkers.forEach { $0.isEnabled = false }
                    self.linkerEntity?.isEnabled = false
                    self.payloadEntity?.isEnabled = false

                    updateAttachmentEntities()
                    
                    
                    // Ensure all payloads are disabled in step 0
//                    self.adcPayloadsInner.forEach { $0.isEnabled = false }
//                    self.adcPayloadsOuter.forEach { $0.isEnabled = false }
                case 1:
                    os_log(.debug, "ITR.. ✅ ADC build step 1 - checkmark to move past antibody to linker")

                    self.antibodyRootEntity?.components.remove(ADCGestureComponent.self)
                    for (index, element) in adcLinkers.enumerated() {
                        element.isEnabled = index <= dataModel.linkersWorkingIndex
                        element.components.remove(ADCProximitySourceComponent.self)
                    }
                    adcLinkers[dataModel.linkersWorkingIndex].components.set(ADCProximitySourceComponent())
                    
                    print("going to look for linker entity")
                    if let linkerEntity = linkerEntity {
                        print("case 1, found linker entity")
                        if dataModel.isCurrentStepComplete {
                            print("current step is complete, linker entity = \(linkerEntity.isEnabled)")
//                            linkerEntity.opacity = 1
                            linkerEntity.isEnabled = false
                        } else {
                            print("linker step is not complete, enabling linker entity dataModel.isCurrentStepComplete = \(dataModel.isCurrentStepComplete)")
                            linkerEntity.isEnabled = true
                            linkerEntity.opacity = 1
                            print("setting linker opacity to \(linkerEntity.opacity)")
                        }
                        if !dataModel.manualStepTransition {
                            print("manualStepTransition = \(dataModel.manualStepTransition)")
                            linkerEntity.opacity = 0
                            print("setting linker opacity to \(linkerEntity.opacity)")
                        }
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
                            // bubblePopSound.toggle()
                            
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
                            
                            // Only advance step after visuals are complete
                            // dataModel.adcBuildStep = 3
                        }
                    }
                    
                    self.adcLinkers.forEach { $0.isEnabled = true }
                    self.linkerEntity?.isEnabled = false
                    self.linkerAttachmentEntity?.isEnabled = false
                    
//                    if let payloadEntity = payloadEntity {
//                        if dataModel.isCurrentStepComplete {
//                            payloadEntity.isEnabled = true
//                        }
//                        payloadEntity.isEnabled = false
//                        payloadEntity.opacity = 0
//                    }
                    
                    print("going to look for payload entity")
                    if let payloadEntity = payloadEntity {
                        print("case 1, found payloadEntity entity")
                        if dataModel.isCurrentStepComplete {
                            print("current step is complete, payloadEntity entity = \(payloadEntity.isEnabled)")
                            payloadEntity.isEnabled = false
                        } else {
                            print("payloadEntity step is not complete, enabling payloadEntity  dataModel.isCurrentStepComplete = \(dataModel.isCurrentStepComplete)")
                            payloadEntity.isEnabled = true
                            payloadEntity.opacity = 1
                            print("setting payloadEntity opacity to \(payloadEntity.opacity)")
                        }
                        if !dataModel.manualStepTransition {
                            print("manualStepTransition = \(dataModel.manualStepTransition)")
                            payloadEntity.opacity = 0
                            print("setting payloadEntity opacity to \(payloadEntity.opacity)")
                        }
                    }
                    
                    
                    // Restore payload setup code
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
                    // play animation sequence
                    if !dataModel.manualStepTransition {
                        print("dataModel.manualStepTransition = \(dataModel.manualStepTransition) Must play animation sequence")
                        Task { @MainActor in
                            if let antibodyRootEntity = antibodyRootEntity {
                                os_log(.debug, "ITR..🔍 Starting ADC animation sequence")
                                
                                if let adcComplexEntity = antibodyRootEntity.findEntity(named: "ADC_complex_001") {
                                    os_log(.debug, "ITR..Found ADC_complex_001, starting animation sequence")
                                    os_log(.debug, "ITR..Initial ADC position: %@", String(describing: adcComplexEntity.position))
                                    
                                    
                                    // Move antibody up
                                    await adcComplexEntity.animatePosition(
                                        to: SIMD3(-0.4, 0, 0),
                                        duration: 1.0,
                                        timing: .easeInOut,
                                        waitForCompletion: true
                                    )
                                    os_log(.debug, "ITR..ADC position after move: %@", String(describing: adcComplexEntity.position))
                                    
                                    // Start rotation
                                    os_log(.debug, "ITR..Starting ADC rotation")
                                    adcComplexEntity.startContinuousRotation(speed: 0.5, axis: .xAxis)
                                    
                                    // Move main view back
                                    os_log(.debug, "ITR..Moving main view back to original position")
                                    // After some event (e.g., button tap), return to initial state
                                    await mainViewEntity.animateToPositionAndYRotation(
                                        targetPosition: SIMD3(0, 0, 0),
                                        targetYRotationDegrees: 0,
                                        duration: 1.0,
                                        timing: .easeInOut,
                                        waitForCompletion: true
                                    )
                                    os_log(.debug, "ITR..Main view returned to original position")
                                    
                                } else {
                                    os_log(.error, "ITR..❌ Could not find ADC_complex_001 entity")
                                }
                            } else {
                                os_log(.error, "ITR..❌ No antibody root entity found")
                            }
                        }
                    }
                    

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
                            
                            // Only advance step after visuals are complete
                            // dataModel.adcBuildStep = 4
                            
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
                
                
                    // Reset manual flag for future transitions
                    dataModel.manualStepTransition = false
                
            }
        }
        // Change the Antibody 3D model material color to the selected color
        .onChange(of: dataModel.selectedADCAntibody) { oldValue, newValue in
            os_log(.debug, "ITR..onChange(of: selectedADCAntibody): new value: \(newValue ?? -1)")
            handleAntibodyColorChange(newValue: newValue)
        }
        // MARK: When VO Plays
        .onChange(of: dataModel.isVOPlaying) { oldValue, newValue in
            if !newValue {  // VO finished playing
                Task { @MainActor in
                    os_log(.debug, "ITR..VO finished playing, current step: \(dataModel.adcBuildStep)")
                    // Fade in the appropriate entities based on current step
                    switch dataModel.adcBuildStep {
                    // MARK: Fade in Antibody
                    case 0:  // Initial fade in of antibody
                        // if dataModel.adcBuildStep == 0 && !dataModel.hasInitialVOCompleted {
                        //     dataModel.hasInitialVOCompleted = true
                        //     // dataModel.showSelector = true
                        // }
                        dataModel.hasInitialVOCompleted = true
                        dataModel.antibodyVOCompleted = true
                        
                        // Reset entity
                        mainViewEntity.transform = Transform.identity
                        Logger.debug("Reset to Pos: \(mainViewEntity.transform.translation), Rot: \(mainViewEntity.transform.rotation.angle * 180 / .pi)°")
                        
                        // Move to target position and rotation
                        await mainViewEntity.animateToPositionAndYRotation(
                            targetPosition: SIMD3(-0.5, 0, 0.2),
                            targetYRotationDegrees: 30,
                            duration: 1.0,
                            delay: 0.5,
                            timing: .easeInOut,
                            waitForCompletion: true
                        )
                        
                        // After position animation, fade in antibody with delay
                        if let antibodyEntity = antibodyEntity {
                            os_log(.debug, "ITR..antibodyEntity exists, fading in")
                            await antibodyEntity.fadeOpacity(to: 1, duration: 1.0)
                            antibodyEntity.isEnabled = true
                            os_log(.debug, "ITR..antibodyEntity fade complete, isEnabled set to true")
                        }
                    // MARK: Fade in Linker
                    case 1:  // Fade in linker
                        // dataModel.showSelector = true
                        os_log(.debug, "ITR..Attempting to fade in linker entities")
                        if let linkerEntity = linkerEntity {
                            os_log(.debug, "ITR..linkerEntity exists, isEnabled: \(linkerEntity.isEnabled)")
                            // Fade in entities
                            await linkerEntity.fadeOpacity(to: 1, duration: 1.0)
                            
                            // show the coaching Overlay
                            dataModel.isCoachingOverlayPresent = true
                            Logger.debug("\nShowing coaching overlay\n")
                            
                            linkerEntity.isEnabled = true
                            os_log(.debug, "ITR..linkerEntity fade complete, isEnabled set to true")
                        } else {
                            os_log(.error, "ITR..❌ linkerEntity is nil")
                        }
                    // MARK: Fade in Payload
                    case 2:  // Fade in payload
                        // dataModel.showSelector = true
                        if let payloadEntity = payloadEntity {
                            os_log(.debug, "ITR..Attempting to fade in payloadEntity")
                            os_log(.debug, "ITR..payload.isEnabled: \(payloadEntity.isEnabled)")
                            await payloadEntity.fadeOpacity(to: 1, duration: 1.0)
                            payloadEntity.isEnabled = true
                        }
                    default:
                        os_log(.debug, "ITR..No fade needed for step \(dataModel.adcBuildStep)")
                    }
                    
                    await checkAndAdvanceStep()
                }
            }
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

                    // Change all linkers to the same color
                    for linker in adcLinkers {
                        linker.updateShaderGraphColor(parameterName: "Basecolor_Tint", color: .adc[newValue])
                    }
                }
            }
        }
        // Change the payload inner and outer 3D model material color to the selected color
        .onChange(of: dataModel.selectedPayloadType) { oldValue, newValue in
            os_log(.debug, "ITR..onChange(of: dataModel.selectedPayloadType): New change selected working payload: \(newValue ?? -1)")
            guard dataModel.adcBuildStep == 2  else {
                os_log(.error, "ITR..onChange(of: dataModel.selectedPayloadType): ❌ Error, got a new value for selectedPayloadType: \(newValue ?? -1) but adcBuildStep is not 2")
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
            os_log(.debug, "ITR..onChange(bubblePopSound): 🔊 SYSTEM 1 - Playing through popAudioPlaybackController")
            self.popAudioPlaybackController?.play()
        }

    }
    
    // MARK: - Step Management
    
    /// Checks conditions and advances to the next step if appropriate
    private func checkAndAdvanceStep() async {
        // Don't advance if VO is still playing
        guard !dataModel.isVOPlaying else { return }
        
        switch dataModel.adcBuildStep {
        case 1:  // Linker step
            // Check if we're on the last linker and it's been placed
            if dataModel.linkersWorkingIndex >= (adcLinkers.count - 1) {
                try? await Task.sleep(for: .milliseconds(500))
                dataModel.adcBuildStep = 2
                dataModel.selectedPayloadType = nil
            }
        case 2:  // Payload step
            // Check if we're on the last payload and it's been placed
            if dataModel.payloadsWorkingIndex >= (adcPayloadsInner.count - 1) {
                try? await Task.sleep(for: .milliseconds(500))
                dataModel.adcBuildStep = 3
            }
        default:
            break  // No auto-advancement for other steps
        }
    }
    
    // MARK: - Preparation

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

    private func updateAttachmentEntities() {
        print("dataModel.isCurrentStepComplete: \(dataModel.isCurrentStepComplete)")
        let currentStepComplete = dataModel.isCurrentStepComplete
        linkerAttachmentEntity?.isEnabled = !currentStepComplete
        payloadAttachmentEntity?.isEnabled = !currentStepComplete
    }
    
    private func setupEntitiesAndMaterials(in root: Entity) async {
        // Reset main view entity transform explicitly
        mainViewEntity.transform = .init(scale: .one, rotation: .init(), translation: .zero)
        os_log(.debug, "ADCOptimizedImmersive: Reset mainViewEntity transform to default")
        
        // Add IBL setup first
        do {
            try await IBLUtility
                .addImageBasedLighting(
                    to: root,
                    imageName: "metro_noord_2k",
                    intensity: 0.5
                )
            os_log(.debug, "ADCOptimizedImmersive: Successfully setup IBL lighting")
        } catch {
            os_log(.error, "ADCOptimizedImmersive: Failed to setup IBL with error: %@", error.localizedDescription)
        }
        // Get outline material
        do {
            let materialEntity = try await Entity(named: "Materials/M_outline.usda", in: realityKitContentBundle)
            if let sphereEntity = materialEntity.findEntity(named: "Sphere"),
               let material = sphereEntity.components[ModelComponent.self]?.materials.first as? ShaderGraphMaterial {
                os_log(.debug, "ADCOptimizedImmersive: Successfully loaded outline material")
                self.outlineMaterial = material
            } else {
                os_log(.error, "ADCOptimizedImmersive: Could not find sphere or material in M_outline.usda")
            }
        } catch {
            os_log(.error, "ADCOptimizedImmersive: Failed to load outline material with error: %@", error.localizedDescription)
        }
        
        // Get antibody scene from asset manager
        do {
            let antibodyScene = try await appModel.assetLoadingManager.instantiateAsset(
                withName: "antibody_scene",
                category: .buildADCEnvironment
            )
            os_log(.debug, "ADCOptimizedImmersive: Antibody scene loaded successfully")
            self.antibodyRootEntity = antibodyScene
            // Optionally log some identifying property:
            if let name = antibodyScene.name as String? {
                os_log(.debug, "ADCOptimizedImmersive: Antibody scene name: %@", name)
            }
            prepareAntibodyEntities()
            
            await prepareLinkerEntities()
            await preparePayloadEntities()
            if let rootEntity = antibodyRootEntity {
                prepareTargetEntities(antibodyScene: rootEntity)
            }
            
            self.adcLinkers.forEach { $0.isEnabled = false }
            
            // Create sort group for all ADC components
            self.adcSortGroup = ModelSortGroup(depthPass: .postPass)
            os_log(.debug, "ADCOptimizedImmersive: Created ADC sort group successfully")
        } catch {
            os_log(.error, "ADCOptimizedImmersive: Failed to load antibody scene with error: %@", error.localizedDescription)
        }
    }
}
