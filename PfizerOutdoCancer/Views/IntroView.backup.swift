//
//  IntroView.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 10/23/24.
//

import SwiftUI
import RealityKit
import RealityKitContent


/// A RealityView that creates an immersive lab environment with spatial audio and IBL lighting
struct IntroView2: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel
    @Environment(\.dismissWindow) private var dismissWindow
    
    /// The root entities for the intro scene.
    let immersiveSceneRoot: Entity = Entity()
    
    @State var tunnel: Entity?
    @State var portal: Entity?
    @State var tube: ModelEntity?
    @State var material: ShaderGraphMaterial?
    
    // Timer management
    @State private var transitionTimer: Timer?
    @State private var portalFadeTimer: Timer?
    @State private var portalScaleTimer: Timer?
    @State private var titleTextTimer: Timer?
    
    // Animation states
    @State private var showTitleText = false
    
    // State to drive the animation
    @State private var shouldDimSurroundings = false

    // Computed property for the intensity
    private var tintIntensity: Double {
        shouldDimSurroundings ? 0.02 : 1.0
    }
    //    @State private var tunnelMapAmount: Float = 0.0
    let start = Date()
    
    let portalStart: Double = 103.0
    
    var surroundingsEffect: SurroundingsEffect? {
        let tintColor = Color(red: tintIntensity, green: tintIntensity, blue: tintIntensity)
        return SurroundingsEffect.colorMultiply(tintColor)
    }

    @State private var mainEntity: Entity? = nil
    
    var body: some View {
        VStack {
            TimelineView(.animation) { context in
                RealityView { content, attachments in
                    // Capture content reference
                    let contentRef = content
                    
                    Task {
                        do {
                            // Create a ModelEntity, for example a box
//                            let box = ModelEntity(
//                                mesh: .generateBox(size: 0.1),
//                                materials: [SimpleMaterial(color: .blue, roughness: 0.5, isMetallic: false)]
//                            )
//                            
//                            // Position the box so we can see it
//                            box.position = [0, 1, -1]
//
//                            // Add the box to the scene
//                            contentRef.add(box)
//
//                            // Set the initial transform scale (optional, here it's [1, 1, 1])
//                            box.transform.scale = [1, 1, 1]
//
//                            box.fadeOpacity(from: 0, to: 1, duration: 2.0)
//                            // box.animateZPosition(to: 0.5, duration: 10.0)
//                            box.animateZPositionClosure(to: 0.5, duration: 10.0)

                            // Create lab root
                            let root = Entity()
                            self.mainEntity = root

                            // Add PositioningComponent with desired offsets
                            root.components.set(PositioningComponent(
                                offsetX: 0,
                                offsetY: -1.5,  // Same offset they were using
                                offsetZ: -1.0   // Same offset they were using
                            ))
                            contentRef.add(root)

                            // Then do the rest of the setup
                            guard let introEnvironmentEntity = await appModel.assetLoadingManager.instantiateEntity("intro_environment") else {
                                fatalError()
                            }

                            // Find and set initial opacity for portal warp
                            if let portalWarp = introEnvironmentEntity.findEntity(named: "sh0100_v01_portalWarp2") {
                                print("🎯 Found portal warp entity")
                                portalWarp.opacity = 0.0  // Set initial opacity
                                await portalWarp.fadeOpacity(to: 1, duration: 10.0, delay: 24.0)
                            }
                            
                            

                            // Create portal and add to immersiveSceneRoot
                            let portal = await PortalManager.createPortal(
                                appModel: appModel,
                                environment: immersiveSceneRoot,
                                portalPlaneName: "Plane_001"
                            )
                            portal.position = [0, -0.25, 0]
                            
                            // Set initial opacity to 0
                            portal.opacity = 0.0
                            
                            // Set initial x-scale to 0
                            var transform = portal.transform
                            transform.scale.x = 1.0
                            portal.transform = transform
                            
                            // Store reference to portal 
                            self.portal = portal
                            
                            // Add text attachment to titleRoot
                            if let titleEntity = attachments.entity(for: "titleText") {
                                print("📎 Found titleText attachment")
                                if let titleRoot = portal.findEntity(named: "titleRoot") {
                                    print(" Found titleRoot in portal")
                                    titleEntity.position = [0, -0.25, 0.1]  // Position below logo
                                    titleEntity.scale *= 5.0
                                    titleRoot.addChild(titleEntity)
//                                    titleRoot.animateZPositionClosure(to: 1, duration: 20.0, delay: portalStart)
                                    print("📎 Added titleText to titleRoot")
                                } else {
                                    print("❌ Failed to find titleRoot in portal")
                                }
                            } else {
                                print("❌ Failed to get titleText attachment")
                            }
                            
                            // Add text attachment to titleRoot
                            if let labViewerEntity = attachments.entity(for: "labViewer") {
                                print("📎 Found titleText attachment")
                                if let titleRoot = portal.findEntity(named: "titleRoot") {
                                    print(" Found titleRoot in portal")
                                    labViewerEntity.position = [0, -0.85, 0.2]  // Position below logo
                                    labViewerEntity.scale *= 5.0
                                    titleRoot.addChild(labViewerEntity)
                                    print("📎 Added labViewer to titleRoot")
                                } else {
                                    print("❌ Failed to find titleRoot in portal")
                                }
                            } else {
                                print("❌ Failed to get titleText attachment")
                            }
                            
                            immersiveSceneRoot.addChild(portal)
                            immersiveSceneRoot.addChild(introEnvironmentEntity)

                            root.addChild(immersiveSceneRoot)
                        }
                    }
                } update: { content, attachments in
                    // Find both cylinders for tunnel animation
                    guard let root = content.entities.first,
                          let tube = root.findEntity(named: "portalMesh") as? ModelEntity else {
//                        print("⚠️ Portal mesh not found yet")
                        return
                    }
                    
                    // Get material for cylinder
                    guard var material1 = tube.model!.materials.first as? ShaderGraphMaterial else {
                        fatalError()
                    }

                    // Start portal warp fade at 24 seconds
                    let elapsed = context.date.timeIntervalSince(start)
                    let startDelay: Double = 24.0
                    let duration: Double = 8.0
                    

                    
                    // Only start tunnel animation after delay
                    if elapsed >= startDelay {
                        // Adjust elapsed time by removing the delay
                        let animationTime = elapsed - startDelay
                        // Normalize to 0-1, then multiply by 0.5 to get 0-0.5 range
                        let normalizedTime = min(1.0, max(0.0, Float(animationTime / duration))) * 0.6
                        
                        // Update material
                        try! material1.setParameter(name: "TunnelMapAmount", value: .float(normalizedTime))
                        
                        // Apply materials back to cylinder
                        tube.model!.materials = [material1]
                    }
                } attachments: {
                    // Add any attachments here
                    Attachment(id: "titleText") {
                        OutdoCancer(showTitle: $showTitleText)
                    }
                    Attachment(id: "labViewer") {
                        LabViewerButton()
                    }
                }
            }
            .preferredSurroundingsEffect(surroundingsEffect)
            .onAppear {
                // Main phase transition (134s)
                transitionTimer = Timer.scheduledTimer(withTimeInterval: 134, repeats: false) { _ in
                    Task {
                        await appModel.transitionToPhase(.lab)
                    }
                }

                // Portal fade-in (103s)
//                await self.portal?.fadeOpacity(to: 1.0, duration: 10.0, delay: portalStart)

                // Portal scale animation (103s + 7s)
                if let portal = self.portal {
                    if let portalPlane = portal.findEntity(named: "portalPlane") {
                        // Set initial scale
                        let transform = portalPlane.transform
                        portalPlane.transform = transform
                        
                        // Start scale animation
//                        portalPlane.animateXScale(from: 0, to: 1.0, duration: 15.0, delay: portalStart + 7.0)
                    }
                }

                // Title text animation (110s)
                titleTextTimer = Timer.scheduledTimer(withTimeInterval: portalStart + 7.0, repeats: false) { _ in
                    print("⏰ Timer fired - setting showTitleText to true")
                    withAnimation {
                        showTitleText = true
                    }
                }

                // Dim surroundings at 5 seconds
                Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                    withAnimation(.easeInOut(duration: 20.0)) {
                        shouldDimSurroundings = true
                    }
                }
            }
            .onDisappear {
                transitionTimer?.invalidate()
                portalFadeTimer?.invalidate()
                titleTextTimer?.invalidate()

                transitionTimer = nil
                portalFadeTimer = nil
                titleTextTimer = nil
            }
        }
    }
}
