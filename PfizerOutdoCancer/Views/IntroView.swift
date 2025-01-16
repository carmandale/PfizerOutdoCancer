//
//  IntroView.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 10/23/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

//extension Notification.Name {
//    static let changeToLabNotification = Notification.Name("ChangeToLab")
//}

/// A RealityView that creates an immersive lab environment with spatial audio and IBL lighting
struct IntroView: View {
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
    
    var surroundingsEffect: SurroundingsEffect? {
        let tintColor = Color(red: tintIntensity, green: tintIntensity, blue: tintIntensity)
        return SurroundingsEffect.colorMultiply(tintColor)
    }
    
    // @State private var headTracker = HeadPositionTracker()
    @State private var mainEntity: Entity? = nil

    // private func positionMainEntity() {
    //     headTracker.positionEntityRelativeToUser(mainEntity, offset: [0, -1.5, -1.0])
    // }
    
    var body: some View {
        VStack {
            TimelineView(.animation) { context in
                RealityView { content, attachments in
                    // Capture content reference
                    let contentRef = content
                    
                    Task {
                        do {
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
                            // try await headTracker.ensureInitialized()
                            // print("✅ Head tracking initialized")
                            
                            // Then do the rest of the setup
                            guard let introEnvironmentEntity = await appModel.assetLoadingManager.instantiateEntity("intro_environment") else {
                                fatalError()
                            }

                            // Find and set initial opacity for portal warp
                            if let portalWarp = introEnvironmentEntity.findEntity(named: "sh0100_v01_portalWarp2") {
                                print("🎯 Found portal warp entity")
                                portalWarp.opacity = 0.0  // Set initial opacity
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
                            
                            // // Position after everything is ready and tracking is initialized
                            // print("🎯 Positioning main entity")
                            // positionMainEntity()
                        } catch {
                            print("❌ Error initializing head tracking: \(error)")
                        }
                    }
                } update: { content, attachments in
                    // Find both cylinders for tunnel animation
                    guard let root = content.entities.first,
                          let tube = root.findEntity(named: "portalMesh") as? ModelEntity else {
                        print("⚠️ Portal mesh not found yet")
                        return
                    }
                    
                    // Get material for cylinder
                    guard var material1 = tube.model!.materials.first as? ShaderGraphMaterial else {
                        fatalError()
                    }

                    let elapsed = context.date.timeIntervalSince(start)
                    let startDelay: Double = 24.0
                    let duration: Double = 8.0
                    
                    // Start portal warp fade at 42 seconds
                    if elapsed >= startDelay && elapsed <= (startDelay + 0.1) {  // Small window to trigger
                        if let portalWarp = content.entities.first?.findEntity(named: "sh0100_v01_portalWarp2") {
                            portalWarp.setOpacity(0.3, animated: true, duration: duration)
                        }
                    }
                    
                    // Only start tunnel animation after delay
                    if elapsed >= startDelay {
                        // Adjust elapsed time by removing the delay
                        let animationTime = elapsed - startDelay
                        // Normalize to 0-1, then multiply by 0.5 to get 0-0.5 range
                        let normalizedTime = min(1.0, max(0.0, Float(animationTime / duration))) * 0.5
                        
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
                portalFadeTimer = Timer.scheduledTimer(withTimeInterval: 103, repeats: false) { _ in
                    self.portal?.setOpacity(1.0, animated: true, duration: 5.0)
                }

                // Title text animation (110s)
                titleTextTimer = Timer.scheduledTimer(withTimeInterval: 110, repeats: false) { _ in
                    print("⏰ Timer fired - setting showTitleText to true")
                    withAnimation {
                        showTitleText = true
                    }
                }

                // Dim surroundings at 5 seconds
                Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                    withAnimation(.easeInOut(duration: 15.0)) {
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
        .task {
            await appModel.monitorSessionEvents()
        }
        .task {
            try? await appModel.runARKitSession()
        }
    }
}
