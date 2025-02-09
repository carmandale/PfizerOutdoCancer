import SwiftUI
import RealityKit
import RealityKitContent

/// A RealityView that creates an immersive lab environment with spatial audio and IBL lighting
struct IntroView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel
    @Environment(\.dismissWindow) private var dismissWindow
    
    @State private var tintIntensity: Double = 0.02
    
    var surroundingsEffect: SurroundingsEffect? {
        let tintColor = Color(red: tintIntensity, green: tintIntensity, blue: tintIntensity)
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
            withAnimation(.linear(duration: 30.0)) {
                tintIntensity = 0.02
            }
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