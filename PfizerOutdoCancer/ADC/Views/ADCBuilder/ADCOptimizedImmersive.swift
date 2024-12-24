import SwiftUI
import RealityKit
import RealityKitContent
import OSLog

struct ADCOptimizedImmersive: View {
    @Environment(ADCAppModel.self) var appModel
    @Environment(ADCDataModel.self) var dataModel
    
    @State private var mainEntity: Entity? = nil
    @State private var cameraEntity: RealityKit.Entity = .init()
    @State private var mainViewEntity: RealityKit.Entity = .init()
    
    @State var antibodyRootEntity: Entity?
    
    @State var antibodyEntity: ModelEntity?
    @State var linkerEntity: Entity?
    @State var payloadEntity: Entity?
    
    @State var workingLinker: ModelEntity?
    @State var workingPayloadInner: ModelEntity?
    @State var workingPayloadOuter: ModelEntity?

    @State private var adcLinkers: [ModelEntity] = .init()
    @State private var adcPayloadsInner: [ModelEntity] = .init()
    @State private var adcPayloadsOuter: [ModelEntity] = .init()

    @State var adcAttachmentEntity: ViewAttachmentEntity?
    @State var linkerAttachmentEntity: ViewAttachmentEntity?
    @State var payloadAttachmentEntity: ViewAttachmentEntity?
    
    @State private var shouldAddADCAttachment: Bool = false
    @State private var shouldAddLinkerAttachment: Bool = false
    @State private var shouldAddPayloadAttachment: Bool = false
    @State private var shouldAddMainViewAttachment: Bool = false
    
    @State var refreshFlag = false
    @State var bubblePopSound = false
    
    @State var popAudioFileResource: AudioFileResource?
    @State var popAudioPlaybackController: AudioPlaybackController?
    
    @State var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State var isCameraInitialized = false
    
    let antibodyAttachmentOffset: SIMD3<Float> = SIMD3(-0.45, 0, 0)
    let linkerAttachmentOffset: SIMD3<Float> = SIMD3(0.35, 0, 0)
    let payloadAttachmentOffset: SIMD3<Float> = SIMD3(0.35, 0, 0)
    private let defaultZPosition: Float = -1.0
    let antibodyRootOffset: SIMD3<Float> = SIMD3(0, 1.0, -1.0)
    
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    
    @State private var originalLinkerMaterial: PhysicallyBasedMaterial?
    @State private var originalPayloadInnerMaterial: PhysicallyBasedMaterial?
    @State private var originalPayloadOuterMaterial: ShaderGraphMaterial?
    
    var body: some View {
        RealityView { content, attachments in
            reset()
            
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
                
//                if let resource = antibodyRootEntity?.components[AudioLibraryComponent.self],
//                       let popSound = resource.resources["bubblepop.mp3"] {
//                        print("ITR..prepareAntibodyEntities(): playing popSound")
//                    popAudioFileResource = resource
////                    antibodyRootEntity?.playAudio(popSound)
//                    }

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
            
            // content.add(createCamera())
  
            setupAttachments(attachments: attachments)

            shouldAddADCAttachment = true
            shouldAddMainViewAttachment = true
            
            antibodyRootEntity?.isEnabled = true
            antibodyEntity?.isEnabled = true
            dataModel.adcBuildStep = 0
            
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
                        linkerEntity.position = calculateTargetLinkerPosition()
//                        linkerEntity.look(at: cameraEntity.scenePosition,
//                                          from: linkerEntity.scenePosition,
//                                          relativeTo: nil,
//                                          forward: .positiveZ)
                    }
                    self.linkerAttachmentEntity?.isEnabled = true
                    setLinkerAttachmentPosition()
                    
                    self.payloadEntity?.isEnabled = false
                case 2:
                    os_log(.debug, "ITR.. ✅ ADC build step 2")
                    self.adcLinkers.forEach { $0.isEnabled = true }
                    self.linkerEntity?.isEnabled = false
                    self.linkerAttachmentEntity?.isEnabled = false
                    self.payloadEntity?.isEnabled = true
                    self.payloadEntity?.position = calculateTargetPayloadsPosition()
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
                if let newValue,
                   let workingPayloadInner,
                   let workingPayloadOuter {
                    workingPayloadInner.updatePBREmissiveColor(.adcEmissive[newValue])
                    workingPayloadOuter.updateShaderGraphColor(parameterName: "Constant", color: .adc[newValue])
                }
            }
        }
        .onChange(of: bubblePopSound) { oldValue , newValue in
            self.popAudioPlaybackController?.play()
        }
        // .onReceive(timer) { fireDate in
        //     print("ITR..Timer fired at: \(fireDate), camera position: \(cameraEntity.position)")
        //     if !isCameraInitialized && cameraEntity.position != .zero {
        //         isCameraInitialized = true
        //         stopTimer()
        //         onCameraInitialized()
        //     }
        // }
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
            let billboard = ADCBillboardComponent(offset: [0,-0.2,-0.6],
                                               axisToFollow: [0,1,0],
                                               initializePositionOnlyOnce: true,
                                               isBillboardEnabled: false)
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
            self.adcPayloadsOuter = [payloadOuter0, payloadOuter1, payloadOuter2, payloadOuter3]
            
            // Store original materials with better logging
            if let innerMaterial = payload0.components[ModelComponent.self]?.materials.first as? PhysicallyBasedMaterial {
                self.originalPayloadInnerMaterial = innerMaterial
                os_log(.debug, "ITR..preparePayloadEntities(): ✅ Stored original inner PBR material")
            } else {
                os_log(.error, "ITR..preparePayloadEntities(): ❌ Failed to store inner PBR material")
            }
            
            if let outerMaterial = payloadOuter0.components[ModelComponent.self]?.materials.first as? ShaderGraphMaterial {
                self.originalPayloadOuterMaterial = outerMaterial
                os_log(.debug, "ITR..preparePayloadEntities(): ✅ Stored original outer shader material")
            } else {
                os_log(.error, "ITR..preparePayloadEntities(): ❌ Failed to store outer shader material")
            }
            
            // Apply outline material with detailed logging
            os_log(.debug, "ITR..preparePayloadEntities(): Attempting to load outline material")
            do {
                let materialEntity = try await Entity(named: "Materials/M_outline.usda", in: realityKitContentBundle)
                os_log(.debug, "ITR..preparePayloadEntities(): ✅ Successfully loaded material entity")
                
                if let sphereEntity = materialEntity.findEntity(named: "Sphere") {
                    os_log(.debug, "ITR..preparePayloadEntities(): Found Sphere entity")
                    
                    let components = sphereEntity.components
                    guard let modelComponent = components[ModelComponent.self] else {
                        os_log(.error, "ITR..preparePayloadEntities(): ❌ No ModelComponent found")
                        return
                    }

                    if let material = modelComponent.materials.first as? ShaderGraphMaterial {
                        os_log(.debug, "ITR..preparePayloadEntities(): ✅ Found outline material")
                        
                        // Apply to inner payloads
                        self.adcPayloadsInner.forEach { payload in
                            if var modelComponent = payload.components[ModelComponent.self] {
                                modelComponent.materials = [material]
                                payload.components[ModelComponent.self] = modelComponent
                                payload.isEnabled = false
                                os_log(.debug, "ITR..preparePayloadEntities(): ✅ Applied outline to inner payload")
                            }
                        }
                        
                        // Apply to outer payloads
                        self.adcPayloadsOuter.forEach { payload in
                            if var modelComponent = payload.components[ModelComponent.self] {
                                modelComponent.materials = [material]
                                payload.components[ModelComponent.self] = modelComponent
                                payload.isEnabled = false
                                os_log(.debug, "ITR..preparePayloadEntities(): ✅ Applied outline to outer payload")
                            }
                        }
                    } else {
                        os_log(.error, "ITR..preparePayloadEntities(): ❌ No ShaderGraphMaterial found")
                    }
                } else {
                    os_log(.error, "ITR..preparePayloadEntities(): ❌ Could not find Sphere entity")
                }
            } catch {
                os_log(.error, "ITR..preparePayloadEntities(): ❌ Failed to load outline material: \(error)")
            }
            
            if let innerMaterial = payload0.components[ModelComponent.self]?.materials.first as? PhysicallyBasedMaterial {
                self.originalPayloadInnerMaterial = innerMaterial
                // Apply to all inner payloads
                self.adcPayloadsInner.forEach { payload in
                    if var modelComponent = payload.components[ModelComponent.self] {
                        modelComponent.materials = [innerMaterial]
                        payload.components[ModelComponent.self] = modelComponent
                        payload.updatePBREmissiveColor(.adcWhiteEmissive)  // Now should work
                        payload.isEnabled = false
                    }
                }
            }

            self.adcPayloadsOuter.forEach {
                $0.updateShaderGraphColor(parameterName: "glowColor", color: .adcWhite)

                $0.isEnabled = false
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
           let workingPayloadOuter = payload.findModelEntity(named: "OuterSphere"){
            
            linkerEntity = linker

            // let linkerBillboard = ADCBillboardComponent(offset: [0,-0.2,-0.6],
            //                                    axisToFollow: [0,1,0],
            //                                    initializePositionOnlyOnce: true,
            //                                    isBillboardEnabled: false)
            // linker.components.set(linkerBillboard)
            linker.isEnabled = false
            
            let aLinker = adcLinkers[dataModel.linkersWorkingIndex]
            linker.components.set(createLinkerGestureComponent(linkerEntity: linker, linkerTarget: aLinker))
//            linker.components.set(HoverEffectComponent())
            workingLinker.components.set(ADCProximityComponent(minScale: 0.2, maxScale: 1.0, minProximity: 0.1, maxProximity: 0.5))
            
            
            self.mainEntity?.addChild(linker)
            
            payloadEntity = payload
            
            // let payloadBillboard = ADCBillboardComponent(offset: [0,-0.2,-0.6],
            //                                    axisToFollow: [0,1,0],
            //                                    initializePositionOnlyOnce: true,
            //                                    isBillboardEnabled: false)
            // payload.components.set(payloadBillboard)
            payload.components.set(createGestureComponent())
            
            let aPayload = adcPayloadsInner[dataModel.payloadsWorkingIndex]
            payload.components.set(createPayloadGestureComponent(payloadEntity: payload, payloadTarget: aPayload))
//            payload.components.set(HoverEffectComponent())
            
            payload.isEnabled = false
            
            self.mainEntity?.addChild(payload)

            self.workingLinker = workingLinker
            self.workingPayloadInner = workingPayloadInner
            self.workingPayloadOuter = workingPayloadOuter
            workingPayloadOuter.components.set(ADCProximityComponent(minScale: 2.0, maxScale: 15.0, minProximity: 0.15, maxProximity: 0.6))
            workingPayloadInner.components.set(ADCProximityComponent(minScale: 2.0, maxScale: 15.0, minProximity: 0.15, maxProximity: 0.6))

            os_log(.info, "ITR..prepareTargetEntities(): found all ModelEntities")

        } else {
            os_log(.error,"ITR..prepareTargetEntities(): ❌ Error, not all ModelEntities found")
        }
    }
    
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
                if dist < 0.2 {
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
                                if let outlineMaterial = materialEntity.findEntity(named: "M_outline")?.components[ModelComponent.self]?.materials.first {
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
                            if let linkerEntity = self.linkerEntity {
                                linkerEntity.position = calculateTargetLinkerPosition()
                                linkerEntity.look(at: cameraEntity.scenePosition,
                                                  from: linkerEntity.scenePosition,
                                                  relativeTo: nil,
                                                  forward: .positiveZ)
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
                            adcPayloadsOuter[dataModel.payloadsWorkingIndex].updateMaterials { material in
                                material = outerMaterial
                            }
                        }
                        
                        // Then apply selected colors
                        adcPayloadsInner[dataModel.payloadsWorkingIndex].updatePBREmissiveColor(.adcEmissive[dataModel.selectedPayloadType ?? 0])
                        adcPayloadsOuter[dataModel.payloadsWorkingIndex].updateShaderGraphColor(parameterName: "glowColor", color: .adc[dataModel.selectedPayloadType ?? 0])
                        
                        // If there's a next payload, give it the outline material
                        if dataModel.payloadsWorkingIndex < (adcPayloadsInner.count - 1) {
                            do {
                                let materialEntity = try await Entity(named: "Materials/M_outline.usda", in: realityKitContentBundle)
                                if let rootEntity = materialEntity.findEntity(named: "Root"),
                                   let outlineMaterial = rootEntity.components[ModelComponent.self]?.materials.first {
                                    // Apply outline to both parts of next payload
                                    if var modelComponent = adcPayloadsInner[dataModel.payloadsWorkingIndex + 1].components[ModelComponent.self] {
                                        modelComponent.materials = [outlineMaterial]
                                        adcPayloadsInner[dataModel.payloadsWorkingIndex + 1].components[ModelComponent.self] = modelComponent
                                    }
                                    if var modelComponent = adcPayloadsOuter[dataModel.payloadsWorkingIndex + 1].components[ModelComponent.self] {
                                        modelComponent.materials = [outlineMaterial]
                                        adcPayloadsOuter[dataModel.payloadsWorkingIndex + 1].components[ModelComponent.self] = modelComponent
                                    }
                                }
                            } catch {
                                os_log(.error, "ITR..createPayloadGestureComponent(): ❌ Failed to load M_outline material: \(error)")
                            }
                        }
                        
                        adcPayloadsOuter.forEach {
                            $0.components.remove(ADCProximitySourceComponent.self)
                        }
                        if dataModel.payloadsWorkingIndex >= (adcPayloadsInner.count - 1) {
                            dataModel.adcBuildStep = 3
                        } else {
                            self.payloadEntity?.position = calculateTargetPayloadsPosition()
                            
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
    
    // MARK: - Timer
    
    func stopTimer() {
        timer.upstream.connect().cancel()
    }
    
    func startTimer(seconds: TimeInterval) {
        timer = Timer.publish(every: seconds, on: .main, in: .common).autoconnect()
    }
    
    // MARK: - Extra stuff
    
    func calculateMainViewPosition() -> SIMD3<Float> {
//        let cameraPosition = cameraEntity.position(relativeTo: nil)
        let antibodyPosition = antibodyEntity?.position(relativeTo: nil) ?? [0, 1.5, defaultZPosition]  
        
        return SIMD3<Float>(
            antibodyPosition.x + -0.5,
            antibodyPosition.y + 0,
            antibodyPosition.z + 0
        )
        // calculateRadialPosition(cameraPosition: cameraPosition, 
        //                              antibodyPosition: antibodyPosition, 
        //                              angleDegrees: -35, 
        //                              yOffset: antibodyPosition.y, 
        //                              radiusOffset: 0.1)
    }
    
    func calculateTargetLinkerPosition() -> SIMD3<Float> {
        let antibodyPosition = antibodyEntity?.position(relativeTo: nil) ?? [0, 1.5, defaultZPosition]
        
        // Return position 0.5 meters to the right of the antibody
        return SIMD3<Float>(
            antibodyPosition.x + linkerAttachmentOffset.x,  // 0.5 meters to the right
            antibodyPosition.y + linkerAttachmentOffset.y,        // same height
            antibodyPosition.z + linkerAttachmentOffset.z         // same depth
        )
    }
    func calculateTargetPayloadsPosition() -> SIMD3<Float> {
        
//        let cameraPosition = cameraEntity.position(relativeTo: nil)
        let antibodyPosition = antibodyEntity?.position(relativeTo: nil) ?? [0, 1.5, defaultZPosition]
        
        return SIMD3<Float>(
            antibodyPosition.x + payloadAttachmentOffset.x,  // 0.5 meters to the right
            antibodyPosition.y + payloadAttachmentOffset.y,        // same height
            antibodyPosition.z + payloadAttachmentOffset.z         // same depth
        )
        // calculateRadialPosition(cameraPosition: cameraPosition, antibodyPosition: antibodyPosition, angleDegrees: 35, yOffset: antibodyPosition.y, radiusOffset: 0.1)

    }
    
    func setAntibodyAttachmentPosition() {
        
        // let cameraPosition = cameraEntity.position(relativeTo: nil)
        // let antibodyPosition = antibodyEntity?.position(relativeTo: nil) ?? [0, 1.5, defaultZPosition]
        
        // let newPosition = calculateRadialPosition(cameraPosition: cameraPosition, antibodyPosition: antibodyPosition, angleDegrees: 35, yOffset: antibodyPosition.y, radiusOffset: 0.1)
        // adcAttachmentEntity?.position = newPosition
    }
    
    func setLinkerAttachmentPosition() {
        if let linkerAttachmentEntity, let linkerEntity {
            linkerAttachmentEntity.position = linkerEntity.position(relativeTo: nil) + linkerAttachmentOffset
        }
    }
    
    func calculateRadialPosition(cameraPosition camera: SIMD3<Float>, antibodyPosition antibody: SIMD3<Float>, angleDegrees: Float, yOffset: Float, radiusOffset: Float = 0.0) -> SIMD3<Float>  {
        let c: SIMD3<Float> = [camera.x,0,camera.z]
        let a: SIMD3<Float> = [antibody.x ,0,antibody.z]

        let directionVector = a - c
        let radius = length(directionVector)
        let normalizedAC = directionVector.adcNormalized

        let aAngleRadians = atan2(normalizedAC.z, normalizedAC.x)
        let aAngleDegrees = aAngleRadians * 180 / .pi

        let newAngleDegrees = (aAngleDegrees + angleDegrees)
        let newAngleRadians = newAngleDegrees * .pi / 180

        let x = (radius + radiusOffset) * cos(newAngleRadians)
        let z = (radius + radiusOffset) * sin(newAngleRadians)

        let b: SIMD3<Float> = [x,yOffset,z] + c
        
        return b
    }
    
    
    func updateADC() {
//        os_log(.debug, "ITR..updateADC() called")
        mainViewEntity.isEnabled = shouldAddMainViewAttachment
        if shouldAddMainViewAttachment {
            //Calculate the new position of mainViewEntity
            // mainViewEntity.position = calculateMainViewPosition()
        }
        if (dataModel.adcBuildStep == 0) {
            if let adcAttachmentEntity {
                if shouldAddADCAttachment {
                    mainEntity?.addChild(adcAttachmentEntity)
                    
//                    if let antibodyEntity {
//                        self.adcAttachmentEntity?.position = antibodyEntity.position(relativeTo: nil) + antibodyAttachmentOffset
//                    }
                    // setAntibodyAttachmentPosition()
                    
                } else {
                    mainEntity?.removeChild(adcAttachmentEntity)
                }
            }
            self.linkerAttachmentEntity?.isEnabled = false
            if let payloadAttachmentEntity { payloadEntity?.removeChild(payloadAttachmentEntity) }
        }
        if (dataModel.adcBuildStep == 1) {
            // if let adcAttachmentEntity { mainEntity?.removeChild(adcAttachmentEntity) }
            setLinkerAttachmentPosition()
            if shouldAddLinkerAttachment {
                self.linkerAttachmentEntity?.isEnabled = true

            } else {
                self.linkerAttachmentEntity?.isEnabled = false
            }
            if let payloadAttachmentEntity { payloadEntity?.removeChild(payloadAttachmentEntity) }
        }
        if (dataModel.adcBuildStep == 2) {
            // if let adcAttachmentEntity { mainEntity?.removeChild(adcAttachmentEntity) }
            self.linkerAttachmentEntity?.isEnabled = false
            if let payloadAttachmentEntity {
                if shouldAddPayloadAttachment {
                    payloadEntity?.addChild(payloadAttachmentEntity)
                } else {
                    payloadEntity?.removeChild(payloadAttachmentEntity)
                }
            }
        }
    }
    
    func setupAttachments(attachments: RealityViewAttachments) {
        if let viewAttachment = attachments.entity(for: ADCUIAttachments.mainADCView) {
            viewAttachment.name = ADCUIAttachments.mainADCView
            viewAttachment.scale = SIMD3<Float>(0.6, 0.6, 0.6)
            mainViewEntity.addChild(viewAttachment)
        }
    }
    
    // MARK - Camera
    
    func createCamera() -> Entity {
        os_log(.debug, "ITR..createCamera() called")
        cameraEntity.name = "cameraEntity"
#if targetEnvironment(simulator)
        cameraEntity.position = [0,1.5,0]
#endif
        cameraEntity.components.set(ADCCameraComponent())
        return cameraEntity
    }
    
    func onCameraInitialized() {
        os_log(.debug, "ITR..onCameraInitialized() called")
        Task { @MainActor in
            // mainViewEntity.position = calculateMainViewPosition()
            // linkerEntity?.position = calculateTargetLinkerPosition()
            // payloadEntity?.position = calculateTargetPayloadsPosition()
            
            // setAntibodyAttachmentPosition()
            // setLinkerAttachmentPosition()

        }
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
