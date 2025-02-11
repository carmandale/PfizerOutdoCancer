import SwiftUI
import RealityKit
import RealityKitContent

/// A RealityView that creates an immersive lab environment with spatial audio and IBL lighting
struct IntroView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel
    @Environment(\.dismissWindow) private var dismissWindow
    
    @State private var introTintIntensity: Double = 0.02 {
        didSet {
            print("introTintIntensity changed to: \(introTintIntensity)")
            // Consider adding a breakpoint here to inspect the call stack
        }
    }
    
    var surroundingsEffect: SurroundingsEffect? {
        let tintColor = Color(red: introTintIntensity, green: introTintIntensity, blue: introTintIntensity)
        return SurroundingsEffect.colorMultiply(tintColor)
    }
    
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
            
            // Handle environment and attachments in Task
            Task { @MainActor in
                do {
                    // Load environment first
                    print("📱 IntroView: Starting environment setup")
                    await appModel.introState.setupEnvironment(in: root)
                    appModel.introState.environmentLoaded = true
                    print("✅ Environment setup complete")
                    
                    // Now that environment is loaded, handle attachments
                    if let titleEntity = attachments.entity(for: "titleText"),
                       let labViewerEntity = attachments.entity(for: "labViewer"),
                       let navToggleEntity = attachments.entity(for: "navToggle") {
                        print("📱 IntroView: Found SwiftUI attachments")
                        
                        // Store attachments in view model
                        appModel.introState.titleEntity = titleEntity
                        appModel.introState.labViewerEntity = labViewerEntity
                        appModel.introState.navToggleEntity = navToggleEntity
                        
                        // Get portal and set up attachments
                        if let portal = appModel.introState.getPortal() {
                            print("✅ Found portal for attachments")
                            
                            // Set up attachments on portal
                            appModel.introState.setupAttachments(
                                for: portal,
                                titleEntity: titleEntity,
                                labViewerEntity: labViewerEntity
                            )
                            
                            // Start animation sequence
                            print("📱 IntroView: Starting animation sequence")
                            await appModel.introState.runAnimationSequence()
                            appModel.introState.isSetupComplete = true
                        }
                    }
                } catch {
                    print("❌ IntroView: Setup failed: \(error)")
                }
            }
        } attachments: {
            Attachment(id: "titleText") {
                OutdoCancer(showTitle: $appModel.introState.showTitleText)
            }
            Attachment(id: "labViewer") {
                LabViewerButton()
            }
            Attachment(id: "navToggle") {
                NavToggleView()
            }
        }
        .preferredSurroundingsEffect(surroundingsEffect)
        .onAppear {
            print("\n=== IntroView Appeared ===")
            
            // withAnimation(.linear(duration: 30.0)) {
            //     print(">>> IntroView: Fading in intro tint intensity to %.2f\n", 0.02)
            //     introTintIntensity = 0.02
            // }
        }
        // Keep tracking tasks separate
        .task {
            await appModel.trackingManager.processWorldTrackingUpdates()
        }
        .task {
            await appModel.trackingManager.monitorTrackingEvents()
        }
    }
}
