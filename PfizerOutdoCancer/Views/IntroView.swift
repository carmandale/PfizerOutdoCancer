import SwiftUI
import RealityKit
import RealityKitContent

/// A RealityView that creates an immersive lab environment with spatial audio and IBL lighting
struct IntroView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    
    @State private var introTintIntensity: Double = 0.01 {
        didSet {
            print("introTintIntensity changed to: \(introTintIntensity)")
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
            print("\n=== Setting up IntroView ===")
            
            // Create fresh root entity
            let root = appModel.introState.setupIntroRoot()
            root.components.set(PositioningComponent(
                offsetX: 0,
                offsetY: -1.5,
                offsetZ: -1.0
            ))
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
                do {
                    // Load environment first
                    print("📱 IntroView: Starting environment setup")
                    await appModel.introState.setupEnvironment(in: root)
                    appModel.introState.environmentLoaded = true
                    print("✅ Environment setup complete")
                    
                    // Now that environment is loaded, handle attachments
                    if let titleEntity = attachments.entity(for: "titleText")
                       {
                        print("📱 IntroView: Found SwiftUI attachments")
                        
                        // Store attachments in view model
                        appModel.introState.titleEntity = titleEntity
                        
                        // Get portal and set up attachments
                        if let portal = appModel.introState.getPortal() {
                            print("✅ Found portal for attachments")
                            
                            // Set up attachments on portal
                            appModel.introState.setupAttachments(
                                in: root,
                                for: portal,
                                titleEntity: titleEntity
                            )
                            
                            // Start animation sequence
                            print("📱 IntroView: Starting animation sequence")
                            await appModel.introState.runAnimationSequence()
                            appModel.introState.isSetupComplete = true
                        }
                    }

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
                } catch {
                    print("❌ IntroView: Setup failed: \(error)")
                }
            }
        } attachments: {
            Attachment(id: "titleText") {
                if appModel.introState.showTitleText {
                    OutdoCancer(showTitle: $appModel.introState.showTitleText)
                }
            }
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
//        .preferredSurroundingsEffect(surroundingsEffect)

        .onAppear {
            print("\n=== IntroView Appeared ===")
            dismissWindow(id: AppModel.navWindowId)
            // Ensure library window starts closed
            appModel.updateLibraryWindowState(isOpen: false)
        }
        .onDisappear {
            // Cleanup is now handled by AssetLoadingManager during phase transitions
        }
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
        // start the lab environment when readyToStartLab becomes true
        .onChange(of: appModel.readyToStartLab) { _, newValue in
            if newValue {
                if let root = appModel.introState.introRootEntity {
                    Task { @MainActor in
                        do {
                            try await appModel.labState.setupInitialLabEnvironment(in: root, isIntro: true)
                            try await appModel.labState.setupLabEnvironment(in: root, isIntro: true)
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
