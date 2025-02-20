import SwiftUI
import RealityKit
import RealityKitContent

/// A RealityView that creates an immersive lab environment with spatial audio and IBL lighting
struct IntroView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    
    @State private var introTintIntensity: Double = 0.2 {
        didSet {
            print("introTintIntensity changed to: \(introTintIntensity)")
            // Consider adding a breakpoint here to inspect the call stack
        }
    }
    
    @State private var showNavToggle: Bool = false
    
    var surroundingsEffect: SurroundingsEffect? {
        let tintColor = Color(red: introTintIntensity, green: introTintIntensity, blue: introTintIntensity)
        return SurroundingsEffect.colorMultiply(tintColor)
    }

    @State var handTrackedEntity: Entity = {
        let handAnchor = AnchorEntity(.hand(.left, location: .aboveHand))
        return handAnchor
    }()
    
    var body: some View {
        @Bindable var appModel = appModel
        
        RealityView { content, attachments in
            print("\n=== Setting up IntroView ===")
            print("\n=== hasBuiltSDC = \(appModel.hasBuiltADC) ===")
            
            // Create fresh root entity
            let root = appModel.introState.setupRoot()
            content.add(root)
            print("✅ Added root to content")
            
             if showNavToggle {
                 content.add(handTrackedEntity)
                 if let attachmentEntity = attachments.entity(for: "navToggle") {
                     attachmentEntity.components[BillboardComponent.self] = .init()
                     handTrackedEntity.addChild(attachmentEntity)
                 }
             }
            
            // Handle environment and attachments in Task
            Task { @MainActor in
                // Load environment first
                print("📱 IntroView: Starting environment setup")
                await appModel.introState.setupEnvironment(in: root)
                
                appModel.introState.environmentLoaded = true
                print("✅ Environment setup complete")

                // set up the lab attachments
                // Now that environment is loaded, set up attachments
                if let adcButton = attachments.entity(for: "ADCBuilderViewerButton"),
                   let attackButton = attachments.entity(for: "AttackCancerViewerButton") {
                    
                    // Find attachment points and set up buttons
                    if let builderTarget = root.findEntity(named: "ADCBuilderAttachment") {
                        print("🎯 Found ADCBuilderAttachment target")
                        builderTarget.addChild(adcButton)
                        adcButton.components.set(BillboardComponent())
                        appModel.labState.adcBuilderViewerButtonEntity = adcButton
                    } else {
                        print("❌ ADCBuilderAttachment target not found")
                    }
                    
                    if let attackTarget = root.findEntity(named: "AttackCancerAttachment") {
                        print("🎯 Found AttackCancerAttachment target")
                        attackTarget.addChild(attackButton)
                        attackButton.components.set(BillboardComponent())
                        appModel.labState.attackCancerViewerButtonEntity = attackButton
                    } else {
                        print("❌ AttackCancerAttachment target not found")
                    }
                }
            }
        } attachments: {
            if showNavToggle {
                Attachment(id: "navToggle") {
                    NavToggleView()
                }
            }
            Attachment(id: "ADCBuilderViewerButton") {
                ADCBuilderViewerButton()
            }
            Attachment(id: "AttackCancerViewerButton") {
                AttackCancerViewerButton()
            }
            Attachment(id: "AttachmentContent") {
                HStack(spacing: 12) {
                    Button(action: {
                        appModel.isNavWindowOpen.toggle()
                        openWindow(id: AppModel.navWindowId)
                    }, label: {
                        Image(systemName: "arrow.2.circlepath.circle")
                    })

                }
                .opacity(appModel.isNavWindowOpen ? 0 : 1)
            }
        }
        .installGestures()
        .preferredSurroundingsEffect(surroundingsEffect)
        .onChange(of: appModel.labState.isLibraryOpen) { _, isOpen in
            if isOpen {
                print(">>> Library window opened 🚪")
                openWindow(id: AppModel.libraryWindowId)
                appModel.updateLibraryWindowState(isOpen: true)
            } else {
                print(">>> Library window closed")
                dismissWindow(id: AppModel.libraryWindowId)
                appModel.updateLibraryWindowState(isOpen: false)
            }
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                   appModel.labState.handleTap(on: value.entity)
                }
        )
        // Keep tracking tasks separate
        .task {
            await appModel.trackingManager.processWorldTrackingUpdates()
        }
        .task {
            await appModel.trackingManager.processHandTrackingUpdates()
        }
        .task {
            await appModel.trackingManager.monitorTrackingEvents()
        }
        // Add head position update handler
        .onChange(of: appModel.introState.shouldUpdateHeadPosition) { _, shouldUpdate in
            if shouldUpdate {
                Logger.info("""
                
                🎯 Head Position Update Triggered
                ├─ shouldUpdate: \(shouldUpdate)
                ├─ isReadyForHeadTracking: \(appModel.introState.isReadyForHeadTracking)
                ├─ isPositioningInProgress: \(appModel.introState.isPositioningInProgress)
                ├─ Current Phase: \(appModel.currentPhase)
                ├─ Tracking State: \(appModel.trackingManager.worldTrackingProvider.state)
                └─ Has Device Anchor: \(appModel.trackingManager.worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) != nil)
                """)
            }
            
            if shouldUpdate && appModel.introState.isReadyForHeadTracking && !appModel.introState.isPositioningInProgress {
                if let root = appModel.introState.introRootEntity {
                    // Ensure we're on MainActor
                    Task { @MainActor in
                        Logger.info("""
                        
                        🎯 Starting Head Position Update
                        ├─ Current Position: \(root.position(relativeTo: nil))
                        ├─ Tracking State: \(appModel.trackingManager.worldTrackingProvider.state)
                        ├─ isPositioningInProgress: \(appModel.introState.isPositioningInProgress)
                        └─ isPositioningComplete: \(appModel.introState.isPositioningComplete)
                        """)
                        
                        // Set positioning state first
                        appModel.introState.isPositioningInProgress = true
                        
                        // Update positioning component
                        if var positioningComponent = root.components[PositioningComponent.self] {
                            positioningComponent.needsPositioning = true
                            positioningComponent.shouldAnimate = true
                            positioningComponent.animationDuration = 0.5
                            root.components[PositioningComponent.self] = positioningComponent
                            
                            // Wait for animation plus a small buffer
                            try? await Task.sleep(for: .seconds(0.6))
                            
                            Logger.info("""
                            
                            ✨ Head Position Update Complete
                            ├─ Final Position: \(root.position(relativeTo: nil))
                            ├─ Tracking State: \(appModel.trackingManager.worldTrackingProvider.state)
                            ├─ isPositioningInProgress: \(appModel.introState.isPositioningInProgress)
                            └─ isPositioningComplete: \(appModel.introState.isPositioningComplete)
                            """)
                            
                            // Reset states
                            appModel.introState.shouldUpdateHeadPosition = false
                            appModel.introState.isPositioningComplete = true
                            appModel.introState.isPositioningInProgress = false
                        }
                    }
                }
            }
        }
        // Add positioning completion handler
        .onChange(of: appModel.introState.isPositioningComplete) { _, complete in
            if complete {
                Task { @MainActor in
                    if let root = appModel.introState.introRootEntity,
                       let environment = appModel.introState.introEnvironment {
                        Logger.info("""
                        
                        ✨ Positioning Complete
                        ├─ Phase: \(appModel.currentPhase)
                        ├─ ImmersiveSpaceState: \(appModel.immersiveSpaceState)
                        ├─ Root Entity: \(root.name)
                        └─ Environment Ready: \(environment.name)
                        """)
                        
                        // Now add environment to scene
                        root.addChild(environment)

                        // Get portal and set up attachments
                        if let portal = appModel.introState.getPortal() {
                            print("✅ Found portal for attachments")
                            
                            // Set up attachments on portal
                            appModel.introState.setupAttachments(
                                in: root,
                                for: portal
                            )
                        }
                        
                        // Small delay to ensure everything is settled
                        try? await Task.sleep(for: .seconds(0.3))
                        
                        // Set setup complete before starting animation
                        appModel.introState.isSetupComplete = true
                        
                        // Reset positioning flag before starting animation
                        appModel.introState.isPositioningInProgress = false
                        
                        // Start animation sequence
                        await appModel.introState.runAnimationSequence()
                    }
                }
            }
        }
        // start the lab environment when readyToStartLab becomes true
        .onChange(of: appModel.readyToStartLab) { _, newValue in
            if newValue {
                Logger.info("""
                
                🔄 Starting Lab Setup in IntroView
                ├─ hasBuiltADC: \(appModel.hasBuiltADC)
                ├─ Current Phase: \(appModel.currentPhase)
                └─ readyToStartLab: \(newValue)
                """)
                
                if let root = appModel.introState.introRootEntity {
                    Task { @MainActor in
                        do {
                            try await appModel.labState.setupInitialLabEnvironment(in: root, isIntro: true)
                            // try await appModel.labState.setupLabEnvironment(in: root, isIntro: true)
                        } catch {
                            print("❌ Error setting up lab environment: \(error)")
                        }
                    }
                } else {
                    print("❌ Intro root entity not available for lab setup")
                }
            }
        }
    }
}
