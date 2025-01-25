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
    
    // Timer for auto-transition
    @State private var transitionTimer: Timer?
    @State private var tintIntensity: Double = 0.02
    
    var surroundingsEffect: SurroundingsEffect? {
        let tintColor = Color(red: tintIntensity, green: tintIntensity, blue: tintIntensity)
        return SurroundingsEffect.colorMultiply(tintColor)
    }
    
    var body: some View {
        RealityView { content in
            let root = Entity()
            root.components.set(PositioningComponent(
                offsetX: 0,
                offsetY: -1.5,
                offsetZ: -1.0
            ))
            
            if let outroEnvironmentEntity = await appModel.assetLoadingManager.getOutroEnvironment() {
                root.addChild(outroEnvironmentEntity)
            }
            
            content.add(root)
        }
        .preferredSurroundingsEffect(surroundingsEffect)
        .onAppear {
            transitionTimer = Timer.scheduledTimer(withTimeInterval: 42, repeats: false) { _ in
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
            // Clean up timer
            transitionTimer?.invalidate()
            transitionTimer = nil
        }
        .task {
            await appModel.trackingManager.processWorldTrackingUpdates()
        }
        .task {
            await appModel.trackingManager.monitorTrackingEvents()
        }
    }
}
