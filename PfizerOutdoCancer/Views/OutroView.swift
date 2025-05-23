//
//  OutroView.swift
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
    @Environment(ADCDataModel.self) var dataModel
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    
    // Timer for auto-transition
    @State private var outroTintIntensity: Double = 0.02
    
    var surroundingsEffect: SurroundingsEffect? {
        let tintColor = Color(red: outroTintIntensity, green: outroTintIntensity, blue: outroTintIntensity)
        return SurroundingsEffect.colorMultiply(tintColor)
    }
    
    var body: some View {
        RealityView { content in
            print("\n=== Setting up OutroView ===")
            
            // Create and configure root
            let root = Entity()
            root.name = "OutroRoot"
            root.components.set(PositioningComponent(
                offsetX: 0,
                offsetY: -1.5,
                offsetZ: -1.0
            ))
            print("✅ Created root entity: \(root.name)")
            
            // Add root to content
            content.add(root)
            print("✅ Added root to content")
            
            // Load environment
            do {
                print("📱 OutroView: Loading environment")
                let outroEnvironmentEntity = try await appModel.assetLoadingManager.instantiateAsset(
                    withName: "outro_environment",
                    category: .outroEnvironment
                )
                print("✅ OutroView: Successfully loaded outro environment")
                
                root.addChild(outroEnvironmentEntity)
                print("✅ OutroView: Added environment to root")

                // IBL
                print("📱 OutroViewModel: Setting up IBL lighting")
                try await IBLUtility.addImageBasedLighting(to: root, imageName: "metro_noord_2k")
                print("✅ OutroViewModel: Added IBL lighting")

                root.opacity = 0.0
                await root.fadeOpacity(to: 1.0, duration: 3.0, timing: .easeInOut)
            

            } catch {
                print("❌ OutroView: Failed to load outro environment: \(error)")
            }
        }
         .preferredSurroundingsEffect(surroundingsEffect)
        .task {
            // Wait for environment animation to complete
            try? await Task.sleep(for: .seconds(64))
            print("🎯 OutroView: Transitioning to loading")
            await appModel.transitionToPhase(.loading)
        }
        .onAppear {
            print("\n=== OutroView Appeared ===")
            // Add tint animation
            // withAnimation(.linear(duration: 30.0)) {
            //     outroTintIntensity = 0.02
            // }
        }
        .task {
            await appModel.trackingManager.processWorldTrackingUpdates()
        }
        .task {
            await appModel.trackingManager.monitorTrackingEvents()
        }
    }
}
