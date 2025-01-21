//import SwiftUI
//import RealityKit
//import RealityKitContent
//
///// A RealityView that creates an immersive lab environment with spatial audio and IBL lighting
//struct IntroView.refactor: View {
//    @Environment(AppModel.self) private var appModel
//    @Environment(ADCDataModel.self) var dataModel
//    @Environment(\.dismissWindow) private var dismissWindow
//    
//    // MARK: - Entity States
//    let immersiveSceneRoot: Entity = Entity()
//    @State private var introEnvironment: Entity? = nil
//    @State private var portalWarp: Entity? = nil
//    @State private var portal: Entity? = nil
//    @State var material: ShaderGraphMaterial?
//    @State private var tube: ModelEntity?
//    @State private var mainEntity: Entity? = nil
//    
//    // MARK: - Animation States
//    @State private var showTitleText = false
//    @State private var shouldDimSurroundings = false
//
//
//    
//    let start = Date()
//    let portalStart: Double = 103.0
//    
//    var surroundingsEffect: SurroundingsEffect? {
//        let tintIntensity = appModel.shouldDimSurroundings ? 0.02 : 1.0
//        let tintColor = Color(red: tintIntensity, green: tintIntensity, blue: tintIntensity)
//        return SurroundingsEffect.colorMultiply(tintColor)
//    }
//    
//    var body: some View {
//        VStack {
//            TimelineView(.animation) { context in
//                RealityView { content, attachments in
//                    // Set up root entity
//                    let root = Entity()
//                    mainEntity = root
//                    
//                    root.components.set(PositioningComponent(
//                        offsetX: 0,
//                        offsetY: -1.5,
//                        offsetZ: -1.0
//                    ))
//                    content.add(root)
//                    
//                    // Add environment if loaded
//                    if let environment = introEnvironment {
//                        immersiveSceneRoot.addChild(environment)
//                    }
//                    
//                    // Add portal if loaded
//                    if let p = portal {
//                        immersiveSceneRoot.addChild(p)
//                        
//                        // Add text attachment to titleRoot
//                        if let titleEntity = attachments.entity(for: "titleText") {
//                            print("📎 Found titleText attachment")
//                            if let titleRoot = p.findEntity(named: "titleRoot") {
//                                print(" Found titleRoot in portal")
//                                titleEntity.position = [0, -0.25, 0.1]  // Position below logo
//                                titleEntity.transform.scale *= 5.0
//                                titleRoot.addChild(titleEntity)
//                                print("📎 Added titleText to titleRoot")
//                            } else {
//                                print("❌ Failed to find titleRoot in portal")
//                            }
//                        }
//                        
//                        // Add labViewer attachment to titleRoot
//                        if let labViewerEntity = attachments.entity(for: "labViewer") {
//                            print("📎 Found labViewer attachment")
//                            if let titleRoot = p.findEntity(named: "titleRoot") {
//                                print(" Found titleRoot in portal")
//                                labViewerEntity.position = [0, -0.85, 0.2]  // Position below title
//                                labViewerEntity.transform.scale *= 5.0
//                                titleRoot.addChild(labViewerEntity)
//                                print("📎 Added labViewer to titleRoot")
//                            } else {
//                                print("❌ Failed to find titleRoot in portal")
//                            }
//                        }
//                    }
//                    
//                    root.addChild(immersiveSceneRoot)
//                    
//                } update: { content, attachments in
//                    // Find both cylinders for tunnel animation
////                    guard let root = content.entities.first,
////                          let tube = root.findEntity(named: "portalMesh") as? ModelEntity else {
////                        return
////                    }
////                    
////                    // Get material for cylinder
////                    guard var material1 = tube.model?.materials.first as? ShaderGraphMaterial else {
////                        return
////                    }
////
////                    let elapsed = context.date.timeIntervalSince(start)
////                    let startDelay: Double = 24.0
////                    let duration: Double = 8.0
//                    
////                    if elapsed >= startDelay {
////                        let animationTime = elapsed - startDelay
////                        let normalizedTime = min(1.0, max(0.0, Float(animationTime / duration))) * 0.6
////                        try? material1.setParameter(name: "TunnelMapAmount", value: .float(normalizedTime))
////                        
////                        // Apply materials back to cylinder
////                        tube.model?.materials = [material1]
////                    }
//                } attachments: {
//                    Attachment(id: "titleText") {
//                        OutdoCancer(showTitle: $showTitleText)
//                    }
//                    Attachment(id: "labViewer") {
//                        LabViewerButton()
//                    }
//                }
//            }
//            .preferredSurroundingsEffect(surroundingsEffect)
//        }
//        .task {
//            await loadAndSetupEntities()
//            await runAnimationSequence()
//        }
//    }
//}
//
//// MARK: - Private Methods
//private extension IntroView {
//    func loadAndSetupEntities() async {
//        // Load intro environment
//        guard let environment = await appModel.assetLoadingManager.instantiateEntity("intro_environment") else {
//            print("Failed to load intro environment")
//            return
//        }
//        introEnvironment = environment
//        
//        // Find and setup portal warp
////        if let warp = environment.findEntity(named: "sh0100_v01_portalWarp2") {
////            portalWarp = warp
////            warp.opacity = 0.6
////            
////            // Find and store shader material
////            if let component = warp.components[ModelComponent.self],
////               let material = component.materials.first as? ShaderGraphMaterial {
////                self.material = material
////            }
////        }
//        
//        // Create and setup portal
//        let p = await PortalManager.createPortal(
//            appModel: appModel,
//            environment: environment,
//            portalPlaneName: "Plane_001"
//        )
//        portal = p
//        p.opacity = 0.0
//        p.position = [0, -0.25, 0]
//    }
//    
//    func runAnimationSequence() async {
//        // Dim surroundings at 5 seconds
//        try? await Task.sleep(for: .seconds(5))
//        withAnimation(.easeInOut(duration: 20.0)) {
//            appModel.shouldDimSurroundings = true
//        }
//        
//        // Portal warp fade (24s)
////        try? await Task.sleep(for: .seconds(19)) // (24 - 5)
////        if let warp = portalWarp {
////            await warp.fadeOpacity(to: 1.0, duration: 10.0)
////        }
//        
//        // Portal fade (103s)
//        try? await Task.sleep(for: .seconds(79)) // (103 - 24)
//        if let p = portal {
//            await p.fadeOpacity(to: 1.0, duration: 10.0)
//            
//            // Animate title root forward
//            if let titleRoot = p.findEntity(named: "titleRoot") {
//                await titleRoot.animateZPosition(to: 1.0, duration: 20.0)
//            }
//        }
//        
//        // Portal scale and title text (110s)
//        try? await Task.sleep(for: .seconds(7))
//        if let p = portal, let portalPlane = p.findEntity(named: "portalPlane") {
//            await portalPlane.animateXScale(from: 0, to: 1.0, duration: 15.0)
//        }
//        
//        // Show title text
//        withAnimation {
//            showTitleText = true
//        }
//        
//        // Transition to lab phase (134s)
//        try? await Task.sleep(for: .seconds(24)) // (134 - 110)
//        await appModel.transitionToPhase(.lab)
//    }
//}
