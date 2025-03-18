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
    
    @State private var showNavToggle: Bool = true
    
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
            Logger.debug("\n=== Setting up IntroView ===")
            Logger.debug("\n=== hasBuiltSDC = \(appModel.hasBuiltADC) ===")
            
            // Create fresh root entity
            let root = appModel.introState.setupRoot()
            content.add(root)
            Logger.debug("✅ Added root to content")

            // Create the menu container entity
            let smoothedMenuEntity = Entity()
            smoothedMenuEntity.name = "HandMenuContainer"
            content.add(smoothedMenuEntity)
            Logger.debug("✅ Created hand menu container entity")

            if showNavToggle {
                Logger.debug("✅ Should show nav toggle")
                
                if let navToggleEntity = attachments.entity(for: "navToggle") {
                    Logger.debug("✅ Found navToggle attachment")
                    navToggleEntity.components[BillboardComponent.self] = .init()
                    navToggleEntity.scale = SIMD3<Float>(0.75, 0.75, 0.75)
                    navToggleEntity.position = SIMD3<Float>(-0.035, 0.07, 0.0125)
                    
                    // Properly capture smoothedMenuEntity and add verbose logging
                    let capturedMenuEntity = smoothedMenuEntity // Create strong reference to capture
                    
                    // Track time for less frequent logging
                    var lastLogTime: TimeInterval = 0
                    let logInterval: TimeInterval = 5.0 // Log only every 5 seconds
                    
                    navToggleEntity.components.set(
                        ClosureComponent { [weak appModel, capturedMenuEntity] deltaTime in
                            // Log less frequently to avoid spam
                            let currentTime = CACurrentMediaTime()
                            let shouldLog = currentTime - lastLogTime >= logInterval
                            
                            if shouldLog {
                                lastLogTime = currentTime
                            }
                            
                            // Use weak reference to avoid memory issues
                            guard let appModel = appModel else {
                                if shouldLog { Logger.debug("⚠️ AppModel is nil in hand menu closure") }
                                return
                            }
                            
                            // Use the handTracking from gameState instead of the undefined property
                            guard let target = appModel.gameState.handTracking.getHandPosition(.left) else {
                                if shouldLog { Logger.debug("ℹ️ No left hand position available") }
                                return
                            }
                            
                            let current = capturedMenuEntity.position
                            
                            // Smoother, more stable factor
                            let smoothingFactor: Float = 5.0 // Reduced from 10.0 for stability
                            let newPosition = current + (target - current) * min(smoothingFactor * Float(deltaTime), 1.0)
                            
                            // Update the position of the smoothed entity
                            capturedMenuEntity
                                .setPosition(newPosition, relativeTo: nil)
                        }
                    )
                    
                    // Add child AFTER setting up the component
                    capturedMenuEntity.addChild(navToggleEntity)
                    Logger.debug("✅ Added navToggle to smoothed entity")
                } else {
                    Logger.debug("⚠️ navToggle attachment not found")
                }
            }
            
            // Handle environment and attachments in Task
            Task { @MainActor in
                // Load environment first
                Logger.debug("📱 IntroView: Starting environment setup")
                await appModel.introState.setupEnvironment(in: root)
                
                appModel.introState.environmentLoaded = true
                Logger.debug("✅ Environment setup complete")

                // set up the lab attachments
                // Now that environment is loaded, set up attachments
                if let adcButton = attachments.entity(for: "ADCBuilderViewerButton"),
                   let attackButton = attachments.entity(for: "AttackCancerViewerButton") {
                    
                    // Find attachment points and set up buttons
                    if let builderTarget = root.findEntity(named: "ADCBuilderAttachment") {
                        Logger.debug("🎯 Found ADCBuilderAttachment target")
                        builderTarget.addChild(adcButton)
                        adcButton.components.set(BillboardComponent())
                        appModel.labState.adcBuilderViewerButtonEntity = adcButton
                    } else {
                        Logger.debug("❌ ADCBuilderAttachment target not found")
                    }
                    
                    if let attackTarget = root.findEntity(named: "AttackCancerAttachment") {
                        Logger.debug("🎯 Found AttackCancerAttachment target")
                        attackTarget.addChild(attackButton)
                        attackButton.components.set(BillboardComponent())
                        appModel.labState.attackCancerViewerButtonEntity = attackButton
                    } else {
                        Logger.debug("❌ AttackCancerAttachment target not found")
                    }
                }
            }
        } attachments: {
            if showNavToggle && appModel.hasBuiltADC  { 
                Attachment(id: "navToggle") {
                    NavToggleView()
                }
            }
            // Add OutdoCancerWrapper attachment
            Attachment(id: "outdoCancerTitle") {
                OutdoCancerWrapper(showTitle: $appModel.introState.showTitleText)
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
