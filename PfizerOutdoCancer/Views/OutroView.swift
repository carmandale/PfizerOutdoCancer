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
struct OutroView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    
    /// The root entities for the intro scene.
    let immersiveSceneRoot: Entity = Entity()
    
    /// Head position tracker for positioning entities

    @State private var mainEntity: Entity?
    
    // Timer for auto-transition
    @State private var transitionTimer: Timer?
    @State private var tintIntensity: Double = 0.02
    
    var surroundingsEffect: SurroundingsEffect? {
        let tintColor = Color(red: tintIntensity, green: tintIntensity, blue: tintIntensity)
        return SurroundingsEffect.colorMultiply(tintColor)
    }
    
    var body: some View {
        RealityView { content in
            // Capture content reference
            let contentRef = content

                    
                    if let outroEnvironmentEntity = await appModel.assetLoadingManager.instantiateEntity("outro_environment") {
                        immersiveSceneRoot.addChild(outroEnvironmentEntity)
                    }
                    
                    // Create root entity and store reference
                    let root = Entity()
                    self.mainEntity = root
                    
                    // Add PositioningComponent with desired offsets
                    root.components.set(PositioningComponent(
                        offsetX: 0,
                        offsetY: -1.5,  // Same offset they were using
                        offsetZ: -1.0   // Same offset they were using
                    ))
                    
                    root.addChild(immersiveSceneRoot)
                    contentRef.add(root)

            
        }
        .preferredSurroundingsEffect(surroundingsEffect)
        .onAppear {
            transitionTimer = Timer.scheduledTimer(withTimeInterval: 93, repeats: false) { _ in
                Task { @MainActor in
                    openWindow(id: AppModel.debugNavigationWindowId)
                    appModel.isDebugWindowOpen = true
                    await appModel.transitionToPhase(.intro)
                }
            }
            
            // Add tint animation
            withAnimation(.linear(duration: 30.0)) {
                tintIntensity = 0.02
            }
        }
        .onDisappear {
            transitionTimer?.invalidate()
            transitionTimer = nil
        }
        .task {
            await appModel.monitorSessionEvents()
        }
        .task {
            try? await appModel.runARKitSession()
        }
    }
}
