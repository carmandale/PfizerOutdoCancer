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
            Logger.debug("introTintIntensity changed to: \(introTintIntensity)")
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
            Logger.debug("=== Setting up IntroView ===")
            Logger.debug("hasBuiltSDC = \(appModel.hasBuiltADC)")

            // Create fresh root entity
            let root = appModel.introState.setupRoot()
            content.add(root)
            Logger.debug("✅ Added root to content")
            
            if showNavToggle {
                content.add(handTrackedEntity)
                if let attachmentEntity = attachments.entity(for: "navToggle") {
                    attachmentEntity.components[BillboardComponent.self] = .init()
                    handTrackedEntity.addChild(attachmentEntity)
                }
            }
            
            // Store root entity reference
            appModel.introState.introRootEntity = root
            
            // Handle environment and attachments in Task
            Task { @MainActor in
                // Load environment first
                Logger.debug("📱 Starting environment setup")
                await appModel.introState.setupEnvironment(in: root)
                
                appModel.introState.environmentLoaded = true
                Logger.info("\n=== Environment Setup Complete ===")
                Logger.info("""
                ✨ Environment Details
                ├─ Phase: \(appModel.currentPhase)
                ├─ Root Entity: \(root.name)
                └─ Environment: \(appModel.introState.introEnvironment?.name ?? "")
                """)
                
                // set up the lab attachments
                if appModel.currentPhase == .intro {
                    // Find attachment points and set up buttons
                    if let builderTarget = root.findEntity(named: "ADCBuilderAttachment") {
                        Logger.debug("🎯 Found ADCBuilderAttachment target")
                        if let adcButton = attachments.entity(for: "ADCBuilderViewerButton") {
                            builderTarget.addChild(adcButton)
                            adcButton.components.set(BillboardComponent())
                            appModel.labState.adcBuilderViewerButtonEntity = adcButton
                        }
                    } else {
                        Logger.debug("❌ ADCBuilderAttachment target not found")
                    }
                    
                    if let attackTarget = root.findEntity(named: "AttackCancerAttachment") {
                        Logger.debug("🎯 Found AttackCancerAttachment target")
                        if let attackButton = attachments.entity(for: "AttackCancerViewerButton") {
                            attackTarget.addChild(attackButton)
                            attackButton.components.set(BillboardComponent())
                            appModel.labState.attackCancerViewerButtonEntity = attackButton
                        }
                    } else {
                        Logger.debug("❌ AttackCancerAttachment target not found")
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
                Logger.debug(">>> Library window opened 🚪")
                openWindow(id: AppModel.libraryWindowId)
                appModel.updateLibraryWindowState(isOpen: true)
            } else {
                Logger.debug(">>> Library window closed")
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
                // Log any blocking conditions
                if !appModel.introState.isReadyForHeadTracking || appModel.introState.isPositioningInProgress {
                    Logger.debug("""
                    🎯 Head Position Update Blocked
                    └─ Reason: \(!appModel.introState.isReadyForHeadTracking ? "Not ready for tracking" : "Positioning in progress")
                    """)
                } else {
                    Logger.info("🎯 Head Position Update Ready")
                }
            }
            
            if shouldUpdate && appModel.introState.isReadyForHeadTracking && !appModel.introState.isPositioningInProgress {
                if let root = appModel.introState.introRootEntity {
                    Task { @MainActor in
                        Logger.info("\n=== Head Position Update Started ===")
                        
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
                            Logger.debug("✅ Found portal for attachments")
                            
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
                            Logger.debug("❌ Error setting up lab environment: \(error)")
                        }
                    }
                } else {
                    Logger.debug("❌ Intro root entity not available for lab setup")
                }
            }
        }
    }
}
