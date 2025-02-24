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
    
    // Animation control flags
    var shouldUseSky = true  // New flag to control sky animation
    var skyDarkness: Float = 0.98
    
    // Animation task tracking
    private var animationTask: Task<Void, Never>?
    
    // Entity references
    private var portal: Entity?
    private var skyDome: Entity?
    private var logo: Entity?
    private var titleRoot: Entity?
    private var material: ShaderGraphMaterial?
    private var assembledLab: Entity?
    var introEnvironment: Entity?
    
    // Attachment entities
    var titleEntity: Entity?
    // var labViewerEntity: Entity?
    var navToggleEntity: Entity?
    
    // Animation States
    var showTitleText = false
    var shouldDimSurroundings = false
    var isSetupComplete = false
    
    // New flag to prevent duplicate environment loading
    var environmentLoaded = false
    
    // Dependencies
    var appModel: AppModel!
    
    // Root setup flags
    var isRootSetupComplete = false
    var isEnvironmentSetupComplete = false
    var isHeadTrackingRootReady = false
    var shouldUpdateHeadPosition = false
    var isPositioningComplete = false
    var isPositioningInProgress = false  // Add positioning progress flag
    
    var isReadyForHeadTracking: Bool {
        isRootSetupComplete && 
        isEnvironmentSetupComplete && 
        isHeadTrackingRootReady
    }
    
    // MARK: - Setup Methods
    func setupRoot() -> Entity {
        Logger.debug("""
        
        === INTRO ROOT SETUP in IntroViewModel ===
        ├─ Root Entity: \(introRootEntity != nil)
        ├─ Scene Ready: \(scene != nil)
        └─ Environment Loaded: \(environmentLoaded)
        """)
        
        // Reset state tracking first
        isRootSetupComplete = false
        isEnvironmentSetupComplete = false
        isHeadTrackingRootReady = false
        isPositioningComplete = false
        isPositioningInProgress = false  // Reset positioning progress state
        
        Logger.info("🔄 Starting new intro session: tracking states reset")
        Logger.info("📱 IntroViewModel: Setting up root")
        
        let root = Entity()
        root.name = "IntroRoot"
        root.position = AppModel.PositioningDefaults.intro.position
        
        root.components.set(PositioningComponent(
            offsetX: 0,
            offsetY: -1.5,  // Maintain intro's specific offset
            offsetZ: -1.0,
            needsPositioning: false,
            shouldAnimate: false,
            animationDuration: 0.0
        ))
        
        // Only log success after validation
        guard root.components[PositioningComponent.self] != nil else {
            Logger.error("""
            
            ❌ ROOT SETUP FAILED in IntroViewModel
            └─ Error: Missing positioning component
            """)
            return root
        }
        
        introRootEntity = root
        isRootSetupComplete = true
        isHeadTrackingRootReady = true
        
        Logger.debug("""
        
        === ✅ ROOT SETUP COMPLETE in IntroViewModel ===
        ├─ Entity Name: \(root.name)
        ├─ Position: \(root.position)
        └─ Has Positioning: true
        """)
        
        return root
    }
    
    // MARK: - Setup Environment
    func setupEnvironment(in root: Entity) async {
        Logger.debug("\n=== ENVIRONMENT SETUP in IntroViewModel ===")
        
        var environment: Entity
        do {
            environment = try await appModel.assetLoadingManager.instantiateAsset(
                withName: "intro_environment", 
                category: AssetCategory.introEnvironment
            )
            Logger.debug("✅ Loaded intro_environment")
            introEnvironment = environment
            
            // if let headTrackedEntity = environment.findEntity(named: "HeadTracker") {
            //     Logger.debug("✅ Found HeadTracker")
            //     if let Cone = environment.findEntity(named: "Cone") {
            //         Logger.debug("""
                    
            //         === HEAD TRACKING SETUP in IntroViewModel ===
            //         ├─ HeadTracker: Found
            //         ├─ Cone: Found
            //         └─ Cone Position: \(Cone.position)
            //         """)
                    
            //         Cone.components.set(FollowComponent())
            //         Logger.debug("✅ Added Follow Component to Cone")
            //     } else {
            //         Logger.error("❌ Cone not found in IntroViewModel")
            //     }
            // } else {
            //     Logger.error("❌ HeadTracker not found in IntroViewModel")
            // }
            
            isEnvironmentSetupComplete = true
            
            // Find and setup entities
            setupSkyDome(in: environment)
            await setupPortal(in: root)
            
            Logger.debug("\n=== ✅ ENVIRONMENT SETUP COMPLETE in IntroViewModel ===\n")
            
        } catch {
            Logger.error("""
            
            ❌ ENVIRONMENT SETUP FAILED in IntroViewModel
            └─ Error: \(error)
            """)
        }
    }
    
    func setupAttachments(in environment: Entity, for portal: Entity, titleEntity: Entity? = nil, labViewerEntity: Entity? = nil) {
        Logger.debug("\n=== ATTACHMENT SETUP in IntroViewModel ===")
        
        // Logo setup
        if let l = environment.findEntity(named: "logo") {
            Logger.debug("""
            
            === LOGO SETUP in IntroViewModel ===
            ├─ Entity: \(l.name)
            ├─ Scale: 0.5
            └─ Initial Opacity: 0
            """)
            
            logo = l
            l.scale = SIMD3<Float>(0.5, 0.5, 0.5)
            l.opacity = 0
        } else {
            Logger.error("❌ Logo entity not found in IntroViewModel")
        }
        
        // Separate title setup
        if let title = environment.findEntity(named: "outdoCancer") {
            Logger.debug("""
            
            === TITLE SETUP in IntroViewModel ===
            ├─ Entity: \(title.name)
            └─ Initial Opacity: 0
            """)
            
            titleRoot = title
            title.opacity = 0
        } else {
            Logger.error("❌ Title entity not found in IntroViewModel")
        }
        
        Logger.debug("\n=== ✅ ATTACHMENT SETUP COMPLETE in IntroViewModel ===\n")
    }
    
    // MARK: - Private Setup Methods
    private func setupSkyDome(in environment: Entity) {
        if let sky = environment.findEntity(named: "SkySphere") {
            Logger.debug("""
            
            === SKY DOME SETUP in IntroViewModel ===
            ├─ Entity: \(sky.name)
            └─ Initial Opacity: 0
            """)
            
            skyDome = sky
            sky.opacity = 0
        } else {
            Logger.error("❌ SkySphere not found in IntroViewModel")
        }
    }
    
    private func setupPortal(in root: Entity) async {
        Logger.debug("\n=== PORTAL SETUP in IntroViewModel ===")
        
        do {
            // Load assembled lab using loadAssembledLab
            let labEnvironment = try await appModel.assetLoadingManager.loadAssembledLab()
            Logger.debug("✅ Loaded assembled lab environment")
            
            assembledLab = labEnvironment
            assembledLab?.name = "assembled_lab"
            
            // Create portal with loaded environment
            let p = await PortalManager.createPortal(
                appModel: appModel,
                environment: labEnvironment,
                portalPlaneName: "Plane_001"
            )
            
            // Store and configure portal
            portal = p
            p.opacity = 0.0
            p.position = [0, -0.25, 0]
            root.addChild(p)
            
            Logger.debug("""
            
            === PORTAL CONFIGURATION in IntroViewModel ===
            ├─ Portal Created ✅
            ├─ Initial Opacity: 0.0
            └─ Position: [0, -0.25, 0]
            """)
            
            // Setup ADC components
            Logger.debug("\n=== ADC SETUP in IntroViewModel ===")
            await appModel.labState.setupADCPlacer(in: root)
            await appModel.labState.setupExtraADCs(in: root)
            
            Logger.debug("\n=== ✅ PORTAL SETUP COMPLETE in IntroViewModel ===\n")
            
        } catch {
            Logger.error("""
            
            ❌ PORTAL SETUP FAILED in IntroViewModel
            ├─ Error: \(error)
            └─ Type: \((error as? AssetError)?.localizedDescription ?? "Unknown")
            """)
        }
    }
    
    
    // MARK: - Animation Methods
    func runAnimationSequence() async {
        Logger.debug("\n=== ANIMATION SEQUENCE START ===")
        
        // Only log if something fails
        guard let sky = skyDome, let p = portal else {
            Logger.error("❌ Animation Sequence: Missing required entities")
            return
        }
        
        // Cancel any existing animation task
        animationTask?.cancel()
        
        animationTask = Task { @MainActor in
            let start = Date()
            
            // Example helper guard to ensure an entity is still in the scene (if needed)
            @MainActor
            func ensureValidEntity(_ entity: Entity?, with name: String) -> Bool {
                if let e = entity, e.parent != nil {
                    return true
                } else {
                    Logger.error("⚠️ Entity \(name) is no longer valid or not attached.")
                    return false
                }
            }
            
            // Check for cancellation before each animation step
            guard !Task.isCancelled else {
                Logger.error("🛑 Animation sequence cancelled before sky fade")
                return
            }
            
            // Sky fade animation
            if shouldUseSky {
                if let s = skyDome {
                    await s.fadeOpacity(to: skyDarkness, duration: 10.0)
                } else {
                    Logger.error("❌ Sky: skyDome not found")
                }
            }
            
            try? await Task.sleep(for: .seconds(29)) // changed from 19 to 29 since removed portalWarp
            
            guard !Task.isCancelled else {
                Logger.error("🛑 Animation sequence cancelled before logo")
                return
            }
            
            // Logo and title sequence
            try? await Task.sleep(for: .seconds(75))
            
            // Verify both entities before starting animation sequence
            guard ensureValidEntity(logo, with: "logo") else {
                Logger.error("❌ Logo entity not valid or missing before animation")
                return
            }
            guard ensureValidEntity(titleRoot, with: "title") else {
                Logger.error("❌ Title entity not valid or missing before animation")
                return
            }
            
            
            if let l = logo, let t = titleRoot {
                // Start logo animation
                let logoAnimation = Task {
                    await l.fadeOpacity(to: 1.0, duration: 5.0)
                }
                
                // Wait for logo animation and delay
                await logoAnimation.value
                try? await Task.sleep(for: .seconds(5))
                
                // Start title animation
                Logger.debug("🔍 Title initial state - opacity: \(t.opacity)")
                let titleAnimation = Task {
                    await t.fadeOpacity(to: 1.0, duration: 5.0)
                }
                
                // Wait for title animation to complete
                await titleAnimation.value
                
            } else {
                Logger.error("❌ Logo or Title entity became invalid during animation sequence")
            }
            
            guard !Task.isCancelled else {
                Logger.error("🛑 Animation sequence cancelled before portal")
                return
            }
            
            // Portal sequence
            guard ensureValidEntity(portal, with: "portal") else { return }
            if let p = portal {
                await p.fadeOpacity(to: 1.0, duration: 5.0)
                try? await Task.sleep(for: .seconds(5.0))
                
                // Perform the original portalPlane X-scale animation
                if let portalPlane = p.findEntity(named: "portalPlane") {
                    await portalPlane.animateXScale(from: 0, to: 1.0, duration: 1.0)
                } else {
                    Logger.error("❌ Portal plane: portalPlane not found")
                }

                // Wait 2 seconds after portalPlane animation finishes
                try? await Task.sleep(for: .seconds(2.0))

                // Concurrent animations – first verify that all required entities are still valid.
                guard let portalRoot = p.findEntity(named: "portalRoot"),
                      let portalWorld = p.findEntity(named: "world"),
                      let portalPlane2 = p.findEntity(named: "portalPlane"),
                      ensureValidEntity(introEnvironment, with: "introEnvironment"),
                      ensureValidEntity(introRootEntity, with: "introRootEntity"),
                      let _ = introRootEntity?.findEntity(named: "ExtraItems"),
                      ensureValidEntity(logo, with: "logo"),
                      ensureValidEntity(titleRoot, with: "titleRoot"),
                      ensureValidEntity(skyDome, with: "skyDome")
                else {
                    Logger.error("""
                    
                    ❌ CONCURRENT ANIMATION FAILED in IntroViewModel
                    ├─ PortalRoot: \(p.findEntity(named: "portalRoot") != nil)
                    ├─ World: \(p.findEntity(named: "world") != nil)
                    ├─ PortalPlane: \(p.findEntity(named: "portalPlane") != nil)
                    ├─ IntroEnvironment: \(introEnvironment != nil)
                    ├─ IntroRoot: \(introRootEntity != nil)
                    ├─ Logo: \(logo != nil)
                    ├─ Title: \(titleRoot != nil)
                    └─ SkyDome: \(skyDome != nil)
                    """)
                    return
                }

                // Run concurrent animations
                Logger.debug("\n=== CONCURRENT ANIMATIONS in IntroViewModel ===")

                let moveDuration = 20.0
                
                async let _: () = skyDome!.fadeOpacity(to: 0.0, duration: 10.0)
                async let _: () = logo!.fadeOpacity(to: 0.0, duration: 3.0)
                async let _: () = titleRoot!.fadeOpacity(to: 0.0, duration: 3.0)
                async let animatePortalRoot: () = portalRoot.animateAbsolutePositionAndScale(
                    to: SIMD3<Float>(0, 0, 0),
                    scale: SIMD3<Float>(1, 1, 1),
                    duration: moveDuration,
                    timing: .easeInOut,
                    waitForCompletion: true
                )

                async let animateWorld: () = portalWorld.animateAbsolutePositionAndScale(
                    to: SIMD3<Float>(0, 0.25, 1),
                    scale: SIMD3<Float>(1, 1, 1),
                    duration: moveDuration,
                    timing: .easeInOut,
                    waitForCompletion: true
                )

                async let animatePortalPlaneScale: () = portalPlane2.animateScale(
                    to: 20.0,
                    duration: moveDuration,
                    timing: .easeInOut,
                    waitForCompletion: true
                )
                

                _ = await (animatePortalRoot, animateWorld, animatePortalPlaneScale)
                
                Logger.debug("=== ✅ CONCURRENT ANIMATIONS COMPLETE in IntroViewModel ===\n")
                

                // Wait for 5 seconds
                try? await Task.sleep(for: .seconds(5))
                
                // Unparent the portalWorld from the portal and reparent it to the root while preserving its transform
                if let lab = assembledLab {
                    // Capture the current transform of the lab in world space
                    let worldTransform = lab.transformMatrix(relativeTo: nil)
                    
                    // Remove the lab from its current parent
                    lab.removeFromParent()
                    
                    // Reparent the lab to the intro root entity
                    introRootEntity!.addChild(lab)
                    
                    // Restore the lab's transform
                    lab.setTransformMatrix(worldTransform, relativeTo: nil)
                }

                // Change the portal component to spill out into the world
                if var portalComponent = portalPlane2.components[PortalComponent.self] {
                    portalComponent.crossingMode = .plane(.positiveZ)
                    portalPlane2.components.set(portalComponent)
                } else {
                    Logger.error("❌ PortalComponent not found on portalPlane2.")
                }
                
                if let portalEnv = self.portal {
                    // self.appModel.assetLoadingManager.inspectEntityHierarchy(portalEnv)
                    portalEnv.removeFromParent()
                    self.portal = nil
                    Logger.debug("Removed portal completely from the scene as we transition to lab.")
                }

                if let introEnv = introEnvironment {
                    introEnv.removeFromParent()
                    introEnvironment = nil
                    Logger.debug("Removed introEnvironment completely from the scene as we transition to lab.")
                }
                
                // Enable large room reverb and inspect hierarchy
                introRootEntity!.enableLargeRoomReverb()
                // appModel.assetLoadingManager.inspectEntityHierarchy(introRootEntity!)

                appModel.readyToStartLab = true
                Logger.debug("readyToStartLab set to \(appModel.readyToStartLab)")
                
            } else {
                Logger.error("❌ Portal: portal not found")
            }
            
            Logger.debug("🎬 Animation Sequence: Completed at +\(Date().timeIntervalSince(start))s")
            Logger.info("\n=== ✅ ANIMATION SEQUENCE COMPLETE ===")
        }
        
    }
    
    // MARK: - Entity Access Methods
    func getPortal() -> Entity? {
        return portal
    }
    
    // MARK: - Cleanup
    func cleanup() {
        Logger.info("""
        
        🔄 === INTRO VIEW CLEANUP STATE ===
        ├─ Root Setup: \(isRootSetupComplete)
        ├─ Environment Setup: \(isEnvironmentSetupComplete)
        ├─ Head Tracking Ready: \(isHeadTrackingRootReady)
        ├─ Should Update Position: \(shouldUpdateHeadPosition)
        ├─ Positioning Complete: \(isPositioningComplete)
        ├─ Positioning In Progress: \(isPositioningInProgress)
        ├─ Has Root Entity: \(introRootEntity != nil)
        └─ Has Positioning Component: \(introRootEntity?.components[PositioningComponent.self] != nil)
        """)

        // defer will run this logging after all cleanup is complete
        defer {
            Logger.info("""
            
            🔄 === INTRO VIEW FINAL STATE ===
            ├─ Root Setup: \(isRootSetupComplete)
            ├─ Environment Setup: \(isEnvironmentSetupComplete)
            ├─ Head Tracking Ready: \(isHeadTrackingRootReady)
            ├─ Should Update Position: \(shouldUpdateHeadPosition)
            ├─ Positioning Complete: \(isPositioningComplete)
            ├─ Positioning In Progress: \(isPositioningInProgress)
            ├─ Has Root Entity: \(introRootEntity != nil)
            └─ Has Positioning Component: \(introRootEntity?.components[PositioningComponent.self] != nil)
            """)
        }

        Logger.debug("\n=== Starting IntroViewModel Cleanup ===")
        
        // First, cancel any running animation task
        Logger.debug("🛑 Cancelling animation sequence")
        animationTask?.cancel()
        animationTask = nil
        
        // Clear root entity and scene
        if let root = introRootEntity {
            Logger.debug("🗑️ Removing intro root entity")
            // Reset positioning component before removal
            if var positioningComponent = root.components[PositioningComponent.self] {
                Logger.debug("🎯 Resetting positioning component")
                positioningComponent.needsPositioning = true
                root.components[PositioningComponent.self] = positioningComponent
            }
            root.removeFromParent()
        }

        introRootEntity = nil
        scene = nil
        
        // Animation control flags
        shouldUseSky = true  // New flag to control sky animation
        skyDarkness = 0.98

        // Entity references
        portal = nil
        skyDome = nil
        logo = nil
        titleRoot = nil
        material = nil
        introEnvironment = nil
        
        // Attachment entities
        titleEntity = nil
        navToggleEntity = nil
        
        // Animation States
        showTitleText = false
        shouldDimSurroundings = false
        isSetupComplete = false
        
        // New flag to prevent duplicate environment loading
        environmentLoaded = false

        
        // Root setup flags
        isRootSetupComplete = false
        isEnvironmentSetupComplete = false
        isHeadTrackingRootReady = false
        shouldUpdateHeadPosition = false
        isPositioningComplete = false
        isPositioningInProgress = false  // Add positioning progress flag
        
        appModel.readyToStartLab = false
        
        Logger.debug("✅ Completed IntroViewModel cleanup\n")
    }
    
    private func applyMeshSorting(from parent: Entity, to child: Entity) {
        // Old helper remains in case it's needed elsewhere
        if let sortingComponent = parent.components[ModelSortGroupComponent.self] {
            child.components.set(sortingComponent)
            Logger.debug("✅ Applied ModelSortGroupComponent from \(parent.name) to \(child.name)")
        } else {
            Logger.error("❌ No ModelSortGroupComponent found on \(parent.name) to apply to \(child.name)")
        }
    }
}
