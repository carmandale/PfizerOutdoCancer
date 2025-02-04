//
//  IntroViewModel.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 1/23/25.
//

import Foundation
import RealityKit
import RealityKitContent
import SwiftUI

@Observable
@MainActor
final class IntroViewModel {
    // MARK: - Properties
    var introRootEntity: Entity?
    var scene: RealityKit.Scene?
    
    // Entity references
    private var portalWarp: Entity?
    private var portal: Entity?
    private var skyDome: Entity?
    private var logo: Entity?
    private var material: ShaderGraphMaterial?
    
    // Attachment entities
    var titleEntity: Entity?
    var labViewerEntity: Entity?
    var navToggleEntity: Entity?
    
    // Animation States
    var showTitleText = false
    var shouldDimSurroundings = false
    var isSetupComplete = false
    
    // Dependencies
    var appModel: AppModel!
    
    // MARK: - Setup Methods
    func setupIntroRoot() -> Entity {
        print("📱 IntroViewModel: Setting up intro root")
        let root = Entity()
        root.name = "IntroRoot"
        introRootEntity = root
        return root
    }
    
    func setupEnvironment(in root: Entity) async {
        print("📱 IntroViewModel: Starting environment setup")
        
        // Set up hand tracking
        let handTrackingEntity = appModel.trackingManager.handTrackingManager.setupContentEntity()
        root.addChild(handTrackingEntity)
        
        // Create a separate anchor for the nav toggle UI
        let uiAnchor = AnchorEntity(.hand(.left, location: .aboveHand))
        root.addChild(uiAnchor)
        
        // Attach nav toggle to left hand
        if let navToggleEntity = navToggleEntity {
            navToggleEntity.components[BillboardComponent.self] = BillboardComponent()
            navToggleEntity.scale *= 0.6
            navToggleEntity.position.z -= 0.02
            uiAnchor.addChild(navToggleEntity)
        }
        
        // Load intro environment using on-demand API through appModel.assetLoadingManager
        print("📱 IntroViewModel: Attempting to load intro environment")
        var environment: Entity
        do {
            environment = try await appModel.assetLoadingManager.instantiateAsset(withName: "intro_environment", category: AssetCategory.introEnvironment)
            print("✅ IntroViewModel: Successfully loaded intro environment")
            // Add environment to root
            print("📱 IntroViewModel: Adding environment to root")
            root.addChild(environment)
        } catch {
            print("❌ IntroViewModel: Error loading intro environment: \(error)")
            return
        }
        
        // Find and setup entities
        print("📱 IntroViewModel: Setting up individual entities")
        setupSkyDome(in: environment)
        setupLogo(in: environment)
        await setupPortalWarp(in: environment)
        await setupPortal(in: root)
        
        print("✅ IntroViewModel: Environment setup complete")
    }
    
    func setupAttachments(for portal: Entity, titleEntity: Entity, labViewerEntity: Entity) {
        print("📱 IntroViewModel: Setting up attachments")
        print("🔍 Portal state - opacity: \(portal.opacity), position: \(portal.position)")
        
        // Add text attachment to titleRoot
        if let titleRoot = portal.findEntity(named: "titleRoot") {
            print("📎 Found titleRoot in portal")
            print("🔍 Before - titleEntity position: \(titleEntity.position), scale: \(titleEntity.transform.scale)")
            titleEntity.position = [0, -0.15, 0.2]
            titleEntity.transform.scale *= 5.0
            print("🔍 After - titleEntity position: \(titleEntity.position), scale: \(titleEntity.transform.scale)")
            titleRoot.addChild(titleEntity)
            print("📎 Added titleText to titleRoot")
        } else {
            print("❌ Failed to find titleRoot in portal")
        }
        
        // Add labViewer attachment to titleRoot
        if let titleRoot = portal.findEntity(named: "titleRoot") {
            print("📎 Found titleRoot in portal")
            print("🔍 Before - labViewer position: \(labViewerEntity.position), scale: \(labViewerEntity.transform.scale)")
            labViewerEntity.position = [0, -0.4, 0.3]
            labViewerEntity.transform.scale *= 5.0
            print("🔍 After - labViewer position: \(labViewerEntity.position), scale: \(labViewerEntity.transform.scale)")
            titleRoot.addChild(labViewerEntity)
            print("📎 Added labViewer to titleRoot")
        } else {
            print("❌ Failed to find titleRoot in portal")
        }
    }
    
    // MARK: - Private Setup Methods
    private func setupSkyDome(in environment: Entity) {
        if let sky = environment.findEntity(named: "SkySphere") {
            print("🔍 Found skyDome: \(sky.name)")
            skyDome = sky
            sky.opacity = 0
            print("✅ Set skyDome opacity to 0")
        } else {
            print("❌ Could not find SkySphere in environment")
        }
    }
    
    private func setupLogo(in environment: Entity) {
        if let l = environment.findEntity(named: "logo") {
            print("🔍 Found logo: \(l.name)")
            logo = l
            l.scale = SIMD3<Float>(0.5, 0.5, 0.5)
            l.opacity = 0
            print("✅ Set logo scale to 0.5 and opacity to 0")
        } else {
            print("❌ Could not find logo in environment")
        }
    }
    
    private func setupPortalWarp(in environment: Entity) async {
        if let warp = environment.findEntity(named: "sh0100_v01_portalWarp3") {
            print("🔍 Found portalWarp: \(warp.name)")
            portalWarp = warp
            warp.opacity = 0.6
            print("✅ Set portalWarp opacity to 0.6")
            
            // Find and store shader material
            if let component = warp.components[ModelComponent.self],
               let material = component.materials.first as? ShaderGraphMaterial {
                self.material = material
                print("✅ Found and stored shader material")
            }
        } else {
            print("❌ Could not find portalWarp in environment")
        }
    }
    
    private func setupPortal(in root: Entity) async {
        print("📱 IntroViewModel: Starting portal setup")
        do {
            // Load assembled lab using loadAssembledLab
            let labEnvironment = try await appModel.assetLoadingManager.loadAssembledLab()
            print("✅ IntroViewModel: Successfully loaded assembled laboratory environment")
            
            // Create portal with loaded environment
            let p = await PortalManager.createPortal(
                appModel: appModel,
                environment: labEnvironment,
                portalPlaneName: "Plane_001"
            )
            print("✅ IntroViewModel: Created portal")
            
            // Store and configure portal
            portal = p
            p.opacity = 0.0
            p.position = [0, -0.25, 0]
            root.addChild(p)
            print("✅ IntroViewModel: Portal setup complete")
            
        } catch {
            print("❌ IntroViewModel: Failed to load laboratory environment: \(error)")
            // Handle specific error cases
            if let assetError = error as? AssetError {
                switch assetError {
                case .resourceNotFound:
                    print("❌ IntroViewModel: Lab environment resource not found")
                case .protobufError(let name):
                    print("❌ IntroViewModel: Protobuf error loading lab environment: \(name)")
                default:
                    print("❌ IntroViewModel: Asset error loading lab environment: \(assetError)")
                }
            }
        }
    }
    
    // MARK: - Animation Methods
    func runAnimationSequence() async {
        let start = Date()
        print("🎬 Animation Sequence: Starting at \(start)")
        print("🔍 Entity Check - skyDome: \(skyDome != nil), portalWarp: \(portalWarp != nil), logo: \(logo != nil), portal: \(portal != nil)")
        
        // Sky fade
        if let s = skyDome {
            print("🌟 Sky fade: Starting at +0s")
            print("🔍 Sky initial opacity: \(s.opacity)")
            await s.fadeOpacity(to: 0.9, duration: 10.0, delay: 2.0)
            print("🌟 Sky fade: Completed fade animation")
            print("🔍 Sky final opacity: \(s.opacity)")
        } else {
            print("❌ Sky fade: skyDome not found")
        }
        
        // Portal warp fade (24s)
        print("⏰ Sleeping for 19s before portal warp")
        try? await Task.sleep(for: .seconds(19))
        print("🌀 Portal warp: Starting at +\(Date().timeIntervalSince(start))s")
        print("🔍 PortalWarp reference check: \(portalWarp != nil)")
        if let warp = portalWarp {
            print("🔍 Warp initial opacity: \(warp.opacity)")
            await warp.fadeOpacity(to: 0.8, duration: 10.0)
            print("🌀 Portal warp: Completed fade animation")
            print("🔍 Warp final opacity: \(warp.opacity)")
        } else {
            print("❌ Portal warp: portalWarp not found")
        }
        
        // Logo and title sequence
        print("⏰ Sleeping for 75s before logo")
        try? await Task.sleep(for: .seconds(75))
        print("🎯 Logo: Starting at +\(Date().timeIntervalSince(start))s")
        print("🔍 Logo reference check: \(logo != nil)")
        if let l = logo {
            print("🔍 Logo initial opacity: \(l.opacity)")
            await l.fadeOpacity(to: 1.0, duration: 10.0)
            print("🎯 Logo: Completed fade animation")
            print("🔍 Logo final opacity: \(l.opacity)")
            try? await Task.sleep(for: .seconds(5))
            print("📝 Title: Showing at +\(Date().timeIntervalSince(start))s")
            withAnimation {
                showTitleText = true
            }
        } else {
            print("❌ Logo: logo not found")
        }
        
        // Portal sequence
        print("🌐 Portal: Starting at +\(Date().timeIntervalSince(start))s")
        print("🔍 Portal reference check: \(portal != nil)")
        if let p = portal {
            print("🔍 Portal initial opacity: \(p.opacity)")
            await p.fadeOpacity(to: 1.0, duration: 5.0)
            print("🌐 Portal: Completed fade animation")
            print("🔍 Portal final opacity: \(p.opacity)")
            try? await Task.sleep(for: .seconds(5.0))
            
            if let portalPlane = p.findEntity(named: "portalPlane") {
                print("🌐 Portal plane: Starting scale animation at +\(Date().timeIntervalSince(start))s")
                await portalPlane.animateXScale(from: 0, to: 1.0, duration: 1.0)
                print("🌐 Portal plane: Completed scale animation")
            } else {
                print("❌ Portal plane: portalPlane not found")
            }
        } else {
            print("❌ Portal: portal not found")
        }
        
        print("🎬 Animation Sequence: Completed at +\(Date().timeIntervalSince(start))s")
    }
    
    // MARK: - Entity Access Methods
    func getPortal() -> Entity? {
        return portal
    }
    
    // MARK: - Cleanup
    func cleanup() {
        print("\n=== Starting IntroViewModel Cleanup ===")
        
        // Clear root entity and scene
        if let root = introRootEntity {
            print("🗑️ Removing intro root entity")
            // Reset positioning component before removal
            if var positioningComponent = root.components[PositioningComponent.self] {
                print("🎯 Resetting positioning component")
                positioningComponent.needsPositioning = true
                root.components[PositioningComponent.self] = positioningComponent
            }
            root.removeFromParent()
        }
        introRootEntity = nil
        
        // Clear scene reference
        scene = nil
        
        // Clear entity references
        portalWarp = nil
        portal = nil
        skyDome = nil
        logo = nil
        material = nil
        
        // Clear attachment entities
        titleEntity = nil
        labViewerEntity = nil
        navToggleEntity = nil
        
        // Reset state
        showTitleText = false
        shouldDimSurroundings = false
        isSetupComplete = false
        
        print("✅ Completed IntroViewModel cleanup\n")
    }
}
