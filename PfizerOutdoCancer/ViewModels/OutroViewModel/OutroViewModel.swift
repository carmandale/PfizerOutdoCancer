//
//  OutroViewModel.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 2/2/25.
//

import Foundation
import RealityKit
import RealityKitContent
import SwiftUI

@Observable
@MainActor
final class OutroViewModel {
    // MARK: - Properties
    var outroRootEntity: Entity?
    var scene: RealityKit.Scene?
    
    // Entity references
    private var outroEnvironmentEntity: Entity?
    
    // State
    var isSetupComplete = false
    
    // Dependencies
    var appModel: AppModel!
    
    // MARK: - Setup Methods
    func setupOutroRoot() -> Entity {
        print("📱 OutroViewModel: Setting up root entity")
        let root = Entity()
        root.name = "OutroRoot"
        root.components.set(PositioningComponent(
            offsetX: 0,
            offsetY: -1.5,
            offsetZ: -1.0
        ))
        outroRootEntity = root
        print("✅ OutroViewModel: Root entity configured")
        return root
    }
    
    func setupEnvironment(in root: Entity) async {
        print("📱 OutroViewModel: Starting environment setup")
        
        // IBL
        do {
            print("📱 OutroViewModel: Setting up IBL lighting")
            try await IBLUtility.addImageBasedLighting(to: root, imageName: "metro_noord_2k")
            print("✅ OutroViewModel: Added IBL lighting")
        } catch {
            print("❌ OutroViewModel: Failed to setup IBL: \(error)")
        }

        // Load environment
        do {
            print("📱 OutroViewModel: Loading environment")
            let environment = try await appModel.assetLoadingManager.instantiateAsset(
                withName: "outro_environment",
                category: .outroEnvironment
            )
            print("✅ OutroViewModel: Successfully loaded outro environment")
            
            root.addChild(environment)
            outroEnvironmentEntity = environment
            print("✅ OutroViewModel: Added environment to root")
            
            isSetupComplete = true
        } catch {
            print("❌ OutroViewModel: Failed to load outro environment: \(error)")
        }
    }
} 
