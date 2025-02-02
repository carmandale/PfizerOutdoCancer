import SwiftUI
import RealityKit
import RealityKitContent

/// A RealityView that creates an immersive lab environment with spatial audio and IBL lighting
struct IntroView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel
    @Environment(\.dismissWindow) private var dismissWindow
    
    var surroundingsEffect: SurroundingsEffect? {
        let tintIntensity = appModel.shouldDimSurroundings ? 0.02 : 1.0
        let tintColor = Color(red: tintIntensity, green: tintIntensity, blue: tintIntensity)
        return SurroundingsEffect.colorMultiply(tintColor)
    }
    
    var body: some View {
        @Bindable var appModel = appModel
        
        RealityView { content, attachments in
            print("📱 IntroView: Setting up RealityView")
            // Set up root entity
            let root = appModel.introState.introRootEntity ?? appModel.introState.setupIntroRoot()
            
            root.components.set(PositioningComponent(
                offsetX: 0,
                offsetY: -1.5,
                offsetZ: -1.0
            ))
            content.add(root)
            
            // Store attachments for later setup
            if let titleEntity = attachments.entity(for: "titleText"),
               let labViewerEntity = attachments.entity(for: "labViewer"),
               let navToggleEntity = attachments.entity(for: "navToggle") {
                print("📱 IntroView: Found SwiftUI attachments")
                appModel.introState.titleEntity = titleEntity
                appModel.introState.labViewerEntity = labViewerEntity
                appModel.introState.navToggleEntity = navToggleEntity
            } else {
                print("❌ IntroView: Failed to get SwiftUI attachments")
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
        .onAppear {
        // Make sure the root entity is created as soon as the view appears.
            if appModel.introState.introRootEntity == nil {
                _ = appModel.introState.setupIntroRoot()
                print("📱 IntroView: setupIntroRoot() called in onAppear")
            }
        }
        .task(id: appModel.introState.introRootEntity) {
            guard !appModel.introState.isSetupComplete else {
                print("📱 IntroView: Setup already complete, skipping")
                return
            }
            
            guard let root = appModel.introState.introRootEntity else {
                print("❌ IntroView: No root entity found in task")
                return
            }
            
            print("📱 IntroView: Starting environment setup in task")
            await appModel.introState.setupEnvironment(in: root)
            
            print("📱 IntroView: Checking portal and attachments")
            if let portal = appModel.introState.getPortal() {
                print("✅ IntroView: Found portal")
                
                if let titleEntity = appModel.introState.titleEntity,
                   let labViewerEntity = appModel.introState.labViewerEntity {
                    print("✅ IntroView: Found both SwiftUI attachments")
                    print("📱 IntroView: Setting up portal attachments")
                    
                    appModel.introState.setupAttachments(
                        for: portal,
                        titleEntity: titleEntity,
                        labViewerEntity: labViewerEntity
                    )
                    
                    print("📱 IntroView: Starting animation sequence")
                    await appModel.introState.runAnimationSequence()
                    appModel.introState.isSetupComplete = true
                } else {
                    print("❌ IntroView: Missing one or both SwiftUI attachments")
                }
            } else {
                print("❌ IntroView: Portal not found")
            }
        }
    }
}


