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
    
    // Animation control flags (from intro)
    var shouldUseSky = true
    var skyDarkness: Float = 0.98  // Same value as intro
    
    // Entity references (from intro)
    private var skyDome: Entity?
    
    // MARK: - Setup Methods
    func setupOutroRoot() -> Entity {
        Logger.debug("📱 OutroViewModel: Setting up root entity")
        let root = Entity()
        root.name = "OutroRoot"
        root.components.set(PositioningComponent(
            offsetX: 0,
            offsetY: -1.5,
            offsetZ: -1.0
        ))
        outroRootEntity = root
        Logger.debug("✅ OutroViewModel: Root entity configured")
        return root
    }
    
    func setupEnvironment(in root: Entity) async {
        Logger.debug("📱 OutroViewModel: Starting environment setup")
        
        // Load environment
        do {
            Logger.debug("📱 OutroViewModel: Loading environment")
            let environment = try await appModel.assetLoadingManager.instantiateAsset(
                withName: "outro_environment",
                category: .outroEnvironment
            )
            Logger.debug("✅ OutroViewModel: Successfully loaded outro environment")
            
            root.addChild(environment)
            outroEnvironmentEntity = environment
            Logger.debug("✅ OutroViewModel: Added environment to root")
            
            // Setup sky dome
            setupSkyDome(in: environment)
            
            // IBL
            do {
                Logger.debug("📱 OutroViewModel: Setting up IBL lighting")
                try await IBLUtility.addImageBasedLighting(to: root, imageName: "metro_noord_2k")
                Logger.debug("✅ OutroViewModel: Added IBL lighting")
            } catch {
                Logger.debug("❌ OutroViewModel: Failed to setup IBL: \(error)")
            }
            
            isSetupComplete = true
            
            // Start sky animation once environment is ready
            await startSkyAnimation()
            
        } catch {
            Logger.debug("❌ OutroViewModel: Failed to load outro environment: \(error)")
        }
    }
    
    private func setupSkyDome(in environment: Entity) {
        if let sky = environment.findEntity(named: "SkySphere") {
            Logger.debug("🔍 Found skyDome: \(sky.name)")
            skyDome = sky
            sky.opacity = 0
            Logger.debug("✅ Set skyDome opacity to 0")
        } else {
            Logger.debug("❌ Could not find SkySphere in environment")
        }
    }
    
    // MARK: - Animation Methods
    func startSkyAnimation() async {
        Logger.debug("🌌 Sky: Starting animation")
        if shouldUseSky {
            if let s = skyDome {
                Logger.debug("🔍 Sky initial opacity: \(s.opacity)")
                await s.fadeOpacity(to: skyDarkness, duration: 10.0)
                Logger.debug("🌌 Sky: Completed fade animation")
                Logger.debug("🔍 Sky final opacity: \(s.opacity)")
            } else {
                Logger.debug("❌ Sky: skyDome not found")
            }
        }
    }
    
    // MARK: - Cleanup
    func cleanup() {
        Logger.debug("\n=== Starting OutroViewModel Cleanup ===")
        
        // Clear root entity and scene
        if let root = outroRootEntity {
            Logger.debug("🗑️ Removing outro root entity")
            // Reset positioning component before removal
            if var positioningComponent = root.components[PositioningComponent.self] {
                Logger.debug("🎯 Resetting positioning component")
                positioningComponent.needsPositioning = true
                root.components[PositioningComponent.self] = positioningComponent
            }
            root.removeFromParent()
        }
        outroRootEntity = nil
        scene = nil
        
        // Clear environment entity
        if let environment = outroEnvironmentEntity {
            Logger.debug("🌍 Removing environment entity")
            environment.removeFromParent()
        }
        outroEnvironmentEntity = nil
        
        // Reset state
        isSetupComplete = false
        
        Logger.debug("✅ Completed OutroViewModel cleanup\n")
    }
} 
