import SwiftUI
import RealityKit
import RealityKitContent
import OSLog

struct ADCOptimizedImmersive: View {
    @Environment(ADCAppModel.self) var appModel
    @Environment(ADCDataModel.self) var dataModel
    
    @State var mainEntity: Entity?
    
    @State var cameraEntity: Entity = Entity()
    @State var mainViewEntity : Entity = Entity()
    
    @State var antibodyRootEntity: Entity?
    
    @State var antibodyEntity: ModelEntity?
    @State var linkerEntity: Entity?
    @State var payloadEntity: Entity?
    
    @State var workingLinker: ModelEntity?
    @State var workingPayloadInner: ModelEntity?
    @State var workingPayloadOuter: ModelEntity?


    
    @State var adcLinkers: [ModelEntity] = []
    @State var adcPayloadsInner: [ModelEntity] = []
    @State var adcPayloadsOuter: [ModelEntity] = []

    @State var adcAttachmentEntity: ViewAttachmentEntity?
    @State var linkerAttachmentEntity: ViewAttachmentEntity?
    @State var payloadAttachmentEntity: ViewAttachmentEntity?
    
    @State var shouldAddADCAttachment = false
    @State var shouldAddLinkerAttachment = false
    @State var shouldAddPayloadAttachment = false
    @State var shouldAddMainViewAttachment = false
    
    @State var refreshFlag = false
    @State var bubblePopSound = false
    
    @State var popAudioFileResource: AudioFileResource?
    @State var popAudioPlaybackController: AudioPlaybackController?
    
    @State var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State var isCameraInitialized = false
    
    let antibodyAttachmentOffset: SIMD3<Float> = SIMD3(0.35, 0, 0)
    let linkerAttachmentOffset: SIMD3<Float> = SIMD3(0.1, 0.1, 0)
    let payloadAttachmentOffset: SIMD3<Float> = SIMD3(0, 0.1, 0)
    
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        RealityView { content, attachments in
            reset()
            
            let masterEntity = Entity()
            self.mainEntity = masterEntity
            self.mainEntity?.name = "MainEntity"
            content.add(masterEntity)
            
            self.mainViewEntity.name = "MainViewEntity"
            masterEntity.addChild(self.mainViewEntity)
            
            
            if let antibodyScene = try? await Entity(named: "antibodyScene", in: realityKitContentBundle),
               let antibodyRoot = antibodyScene.findEntity(named: "antibodyProtein_complex_assembled"){

                if let resource = try? await AudioFileResource(named:"/Root/bubblepop_mp3", from: "antibodyScene.usda", in: realityKitContentBundle) {
                    popAudioFileResource = resource
                } else {
                    os_log(.error, "ITR..ADCOptimizedImmersive.RealityView(): ❌ Error, couldn't find Audio in antibodyScene.usda")
                }

                self.antibodyRootEntity = antibodyRoot
                prepareAntibodyEntities()
                prepareLinkerEntities()
                preparePayloadEntities()
                preopareTargetEntities(antibodyScene: antibodyScene)
            } else {
                os_log(.error, "ITR..ADCOptimizedImmersive.RealityView(): ❌ Error, couldn't find Entity from RealityKitContent")
            }
            
            if dataModel.selectedADCAntibody == nil {
                dataModel.selectedADCAntibody = 0
            }
            
            content.add(createCamera())
  
            setupAttachments(attachments: attachments)

            shouldAddADCAttachment = true
            shouldAddMainViewAttachment = true
            
            antibodyRootEntity?.isEnabled = true
            antibodyEntity?.isEnabled = true
            dataModel.adcBuildStep = 0
            
        } update: { content, attachments in
            updateADC()
            
            
        } attachments: {
            Attachment(id: ADCUIAttachments.adcSelectorView) {
                ADCSelectorView()
            }
            Attachment(id: ADCUIAttachments.linkerSelectorView) {
                ADCLinkerSelectorView()
            }
            Attachment(id: ADCUIAttachments.payloadSelectorView) {
                ADCPayloadSelectorView()
            }
            Attachment(id: ADCUIAttachments.mainADCView) {
                ADCBuilderView()
            }
        }
        .installGestures()
        .onChange(of: dataModel.adcBuildStep) { oldValue, newValue in
            Task { @MainActor in
                switch newValue {
                case 0:
                    os_log(.debug, "ITR.. ✅ ADC build step 0")
                    setAntibodyAttachmentPosition()
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
//                        antibodyRootEntity?.components.remove(ProximitySourceComponent.self)
                    
                        if let linkerEntity = linkerEntity {
                            linkerEntity.isEnabled = true
                            linkerEntity.position = calculateTargetLinkerPosition()
                            linkerEntity.look(at: cameraEntity.scenePosition,
                                              from: linkerEntity.scenePosition,
                                              relativeTo: nil,
                                              forward: .positiveZ)
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
            os_log(.debug, "ITR..onChange(of: dataModel.selectedADCAntibody): new change selected ADC: \(newValue ?? -1)")
            Task { @MainActor in
                if let newValue,
                   let antibodyEntity {
                    antibodyEntity.updatePBRDiffuseColor(.adc[newValue])
                }
            }
        }
        .onChange(of: dataModel.selectedLinkerType) { oldValue, newValue in
            os_log(.debug, "ITR..onChange(of: dataModel.selectedLinkerType): new change selected working linker: \(newValue ?? -1)")
            guard dataModel.adcBuildStep == 1  else {
                os_log(.error, "ITR..onChange(of: dataModel.selectedLinkerType): ❌ Error, got a new value for selectedLinkerType: \(newValue ?? -1) but adcBuildStep is not 1")
                return
            }
            Task { @MainActor in
                if let newValue,
                   let workingLinker {
                    workingLinker.updatePBRDiffuseColor(.adc[newValue])
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
                    workingPayloadOuter.updateShaderGraphColor(parameterName: "glowColor", color: .adc[newValue])
                }
            }
        }
        .onChange(of: bubblePopSound) { oldValue , newValue in
            self.popAudioPlaybackController?.play()
        }
        .onReceive(timer) { fireDate in
            print("ITR..Timer fired at: \(fireDate), camera position: \(cameraEntity.position)")
            if !isCameraInitialized && cameraEntity.position != .zero {
                isCameraInitialized = true
                stopTimer()
                onCameraInitialized()
            }
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
    }
    
    func prepareAntibodyEntities() {
        guard let antibodyRoot = antibodyRootEntity else { return }
        
        if let antibody = antibodyRoot.findModelEntity(named: "ADC_complex"){
            
            self.antibodyRootEntity = antibodyRoot

            self.antibodyEntity = antibody
            antibody.isEnabled = false
            
            antibodyRoot.scale *= 2
            self.mainEntity?.addChild(antibodyRoot)
            
            let billboard = ADCBillboardComponent(offset: [0,-0.2,-0.6],
                                               axisToFollow: [0,1,0],
                                               initializePositionOnlyOnce: true,
                                               isBillboardEnabled: false)
            antibodyRoot.components.set(billboard)
            antibodyRoot.components.set(createGestureComponent())

//            antibodyRoot.components.set(ProximitySourceComponent())
            
            let angleDegrees: Float = 30
            let angleRadians: Float = angleDegrees * (.pi / 180)
            antibodyRoot.orientation = simd_quatf(angle: angleRadians, axis: [0, 0, 1]) * antibodyRoot.orientation
            
            if let resource = popAudioFileResource {
                self.popAudioPlaybackController = antibody.prepareAudio(resource)
            }
            
            os_log(.info, "ITR..prepareAntibodyEntities(): found all ModelEntities")

        } else {
            os_log(.error, "ITR..prepareAntibodyEntities(): ❌ Error, not all ModelEntities found")
        }

    }
    
    
    func prepareLinkerEntities() {
        guard let antibodyRoot = antibodyRootEntity else { return }
        
        if let linker0 = antibodyRoot.findModelEntity(named: "linker", from: "linker01_offset"),
           let linker1 = antibodyRoot.findModelEntity(named: "linker", from: "linker02_offset"),
           let linker2 = antibodyRoot.findModelEntity(named: "linker", from: "linker03_offset"),
           let linker3 = antibodyRoot.findModelEntity(named: "linker", from: "linker04_offset"){
            
            self.adcLinkers = [linker0, linker1, linker2, linker3]
            self.adcLinkers.forEach {
                $0.updatePBRDiffuseColor(.adcWhite)
                $0.isEnabled = false
            }

            os_log(.info, "ITR..prepareLinkerEntities(): found all ModelEntities")

        } else {
            os_log(.error, "ITR..prepareLinkerEntities(): ❌ Error, not all ModelEntities found")
        }
    }
    
    func preparePayloadEntities() {
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
            
            self.adcPayloadsInner.forEach {
                $0.updatePBREmissiveColor(.adcWhiteEmissive)
                $0.isEnabled = false
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
    
    func preopareTargetEntities(antibodyScene: Entity) {
        guard adcLinkers.count > 0 else {
            os_log(.error, "ITR..preopareTargetEntities(): ❌ Error, self.adcLinkers is empty. It should have content at this point.")
            return
        }
        
        guard !adcPayloadsInner.isEmpty else {
            os_log(.error, "ITR..preopareTargetEntities(): ❌ Error, self.adcPayloadsInner is empty. It should have content at this point.")
            return
        }

        if let linker = antibodyScene.findEntity(named: "targetLinker"),
           let payload = antibodyScene.findEntity(named: "targetPayload"),
           let workingLinker = linker.findModelEntity(named: "linker"),
           let workingPayloadInner = payload.findModelEntity(named: "InnerSphere"),
           let workingPayloadOuter = payload.findModelEntity(named: "OuterSphere"){
            
            linkerEntity = linker

            let linkerBillboard = ADCBillboardComponent(offset: [0,-0.2,-0.6],
                                               axisToFollow: [0,1,0],
                                               initializePositionOnlyOnce: true,
                                               isBillboardEnabled: false)
            linker.components.set(linkerBillboard)
            linker.isEnabled = false
            
            let aLinker = adcLinkers[dataModel.linkersWorkingIndex]
            linker.components.set(createLinkerGestureComponent(linkerEntity: linker, linkerTarget: aLinker))
//            linker.components.set(HoverEffectComponent())
            workingLinker.components.set(ADCProximityComponent(minScale: 0.2, maxScale: 1.0, minProximity: 0.1, maxProximity: 0.5))
            
            
            self.mainEntity?.addChild(linker)
            
            payloadEntity = payload
            
            let payloadBillboard = ADCBillboardComponent(offset: [0,-0.2,-0.6],
                                               axisToFollow: [0,1,0],
                                               initializePositionOnlyOnce: true,
                                               isBillboardEnabled: false)
            payload.components.set(payloadBillboard)
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

            os_log(.info, "ITR..preopareTargetEntities(): found all ModelEntities")

        } else {
            os_log(.error,"ITR..preopareTargetEntities(): ❌ Error, not all ModelEntities found")
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
                    bubblePopSound.toggle()
                    
                    Task { @MainActor in

                        adcLinkers[dataModel.linkersWorkingIndex].updatePBRDiffuseColor(.adc[dataModel.selectedLinkerType ?? 0])
                        
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
                        adcPayloadsInner[dataModel.payloadsWorkingIndex].updatePBREmissiveColor(.adcEmissive[dataModel.selectedPayloadType ?? 0])
                        adcPayloadsOuter[dataModel.payloadsWorkingIndex] .updateShaderGraphColor(parameterName: "glowColor", color: .adc[dataModel.selectedPayloadType ?? 0])
                        
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
    
    func calculateMainViewPosition() -> SIMD3<Float>{
        
        let cameraPosition = cameraEntity.position(relativeTo: nil)
        let antibodyPosition = antibodyEntity?.position(relativeTo: nil) ??  [0,1.5,-0.5]
        
        return calculateRadialPosition(cameraPosition: cameraPosition, antibodyPosition: antibodyPosition, angleDegrees: -35, yOffset: antibodyPosition.y, radiusOffset: 0.1)
    }
    
    func calculateTargetLinkerPosition() -> SIMD3<Float> {
        
        let cameraPosition = cameraEntity.position(relativeTo: nil)
        let antibodyPosition = antibodyEntity?.position(relativeTo: nil) ??  [0,1.5,-0.5]
        
        return calculateRadialPosition(cameraPosition: cameraPosition, antibodyPosition: antibodyPosition, angleDegrees: 35, yOffset: antibodyPosition.y, radiusOffset: 0.1)

    }
    func calculateTargetPayloadsPosition() -> SIMD3<Float> {
        
        let cameraPosition = cameraEntity.position(relativeTo: nil)
        let antibodyPosition = antibodyEntity?.position(relativeTo: nil) ??  [0,1.5,-0.5]
        
        return calculateRadialPosition(cameraPosition: cameraPosition, antibodyPosition: antibodyPosition, angleDegrees: 35, yOffset: antibodyPosition.y, radiusOffset: 0.1)

    }
    
    func setAntibodyAttachmentPosition() {
        
        let cameraPosition = cameraEntity.position(relativeTo: nil)
        let antibodyPosition = antibodyEntity?.position(relativeTo: nil) ??  [0,1.5,-0.5]
        
        let newPosition = calculateRadialPosition(cameraPosition: cameraPosition, antibodyPosition: antibodyPosition, angleDegrees: 35, yOffset: antibodyPosition.y, radiusOffset: 0.1)
        adcAttachmentEntity?.position = newPosition
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
            mainViewEntity.position = calculateMainViewPosition()
        }
        if (dataModel.adcBuildStep == 0) {
            if let adcAttachmentEntity {
                if shouldAddADCAttachment {
                    mainEntity?.addChild(adcAttachmentEntity)
                    
//                    if let antibodyEntity {
//                        self.adcAttachmentEntity?.position = antibodyEntity.position(relativeTo: nil) + antibodyAttachmentOffset
//                    }
                    setAntibodyAttachmentPosition()
                    
                } else {
                    mainEntity?.removeChild(adcAttachmentEntity)
                }
            }
            self.linkerAttachmentEntity?.isEnabled = false
            if let payloadAttachmentEntity { payloadEntity?.removeChild(payloadAttachmentEntity) }
        }
        if (dataModel.adcBuildStep == 1) {
            if let adcAttachmentEntity { mainEntity?.removeChild(adcAttachmentEntity) }
            setLinkerAttachmentPosition()
            if shouldAddLinkerAttachment {
                self.linkerAttachmentEntity?.isEnabled = true

            } else {
                self.linkerAttachmentEntity?.isEnabled = false
            }
            if let payloadAttachmentEntity { payloadEntity?.removeChild(payloadAttachmentEntity) }
        }
        if (dataModel.adcBuildStep == 2) {
            if let adcAttachmentEntity { mainEntity?.removeChild(adcAttachmentEntity) }
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
        os_log(.debug, "ITR..setupAttachments() called")

        if let viewAttachment = attachments.entity(for: ADCUIAttachments.adcSelectorView) {
            viewAttachment.name = ADCUIAttachments.adcSelectorView
            
            viewAttachment.scale = SIMD3<Float>(0.6, 0.6, 0.6)
            
            viewAttachment.components.set(ADCSimpleBillboardComponent())
//            let billboard = BillboardComponent(offset: [0,0.12,0],
//                                               axisToFollow: [0,0,0],
//                                               initializePositionOnlyOnce: true,
//                                               isBillboardEnabled: true)
//            viewAttachment.components.set(billboard)
            adcAttachmentEntity = viewAttachment
            mainEntity?.addChild(viewAttachment)
        }
        
        if let viewAttachment = attachments.entity(for: ADCUIAttachments.linkerSelectorView) {
            viewAttachment.name = ADCUIAttachments.linkerSelectorView
            viewAttachment.scale = SIMD3<Float>(0.6, 0.6, 0.6)
            viewAttachment.position = SIMD3<Float>(0,0.18,0)
            
            let simpleBillboard = ADCSimpleBillboardComponent()
            viewAttachment.components.set(simpleBillboard)
            
            linkerAttachmentEntity = viewAttachment
            mainEntity?.addChild(viewAttachment)
        }

        if let viewAttachment = attachments.entity(for: ADCUIAttachments.payloadSelectorView) {
            viewAttachment.name = ADCUIAttachments.payloadSelectorView
            viewAttachment.scale = SIMD3<Float>(0.6, 0.6, 0.6)
            viewAttachment.position = SIMD3<Float>(0,0.18,0)
            
            let simpleBillboard = ADCSimpleBillboardComponent()
            viewAttachment.components.set(simpleBillboard)
            
            payloadAttachmentEntity = viewAttachment
            payloadEntity?.addChild(viewAttachment)
        }
        
        if let viewAttachment = attachments.entity(for: ADCUIAttachments.mainADCView) {
            viewAttachment.name = ADCUIAttachments.mainADCView
            viewAttachment.scale = SIMD3<Float>(0.6, 0.6, 0.6)
//            viewAttachment.position = SIMD3<Float>(0,0,-0.5)
            
            let simpleBillboard = ADCSimpleBillboardComponent()
            viewAttachment.components.set(simpleBillboard)
            
//            mainViewEntity.position = SIMD3<Float>(0,1.5,-0.5)
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
            mainViewEntity.position = calculateMainViewPosition()
            linkerEntity?.position = calculateTargetLinkerPosition()
            payloadEntity?.position = calculateTargetPayloadsPosition()
            
            setAntibodyAttachmentPosition()
            setLinkerAttachmentPosition()

        }
    }
}

//#Preview {
//    ADCOptimizedImmersive()
//        .glassBackgroundEffect()
//        .environment(ADCAppModel())
//        .environment(ADCDataModel())
//}
