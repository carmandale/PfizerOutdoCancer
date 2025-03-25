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
    var startButtonPressed = false
    
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
    func setupRoot() -> Entity {  // Renamed from setupIntroRoot
        Logger.info("""
        
        🔄 === INTRO VIEW INITIAL STATE ===
        ├─ Root Setup: \(isRootSetupComplete)
        ├─ Environment Setup: \(isEnvironmentSetupComplete)
        ├─ Head Tracking Ready: \(isHeadTrackingRootReady)
        ├─ Should Update Position: \(shouldUpdateHeadPosition)
        ├─ Positioning Complete: \(isPositioningComplete)
        ├─ Positioning In Progress: \(isPositioningInProgress)
        ├─ Has Root Entity: \(introRootEntity != nil)
        └─ Has Positioning Component: \(introRootEntity?.components[PositioningComponent.self] != nil)
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
        
        Logger.info("""
        
        ✅ Root Setup Complete
        ├─ Root Entity: \(root.name)
        ├─ Position: \(root.position(relativeTo: nil))
        └─ Positioning: Ready for explicit updates
        """)
        
        introRootEntity = root
        isRootSetupComplete = true
        isHeadTrackingRootReady = true
        return root
    }
    
    // MARK: - Setup Environment
    func setupEnvironment(in root: Entity) async {
        Logger.debug("📱 IntroViewModel: Starting environment setup")
        
        // Load intro environment using on-demand API through appModel.assetLoadingManager
        Logger.debug("📱 IntroViewModel: Attempting to load intro environment")
        var environment: Entity
        do {
            environment = try await appModel.assetLoadingManager.instantiateAsset(withName: "intro_environment", category: AssetCategory.introEnvironment)
            Logger.debug("✅ IntroViewModel: Successfully loaded intro environment")
            // Store but don't add to root yet
            introEnvironment = environment
            
            isEnvironmentSetupComplete = true
            Logger.debug("✅ Environment setup complete")
        } catch {
            Logger.debug("❌ IntroViewModel: Error loading intro environment: \(error)")
            return
        }
        
        // Find and setup entities
        Logger.debug("📱 IntroViewModel: Setting up individual entities")
        setupSkyDome(in: environment)
        await setupPortal(in: root)
        
        Logger.debug("✅ IntroViewModel: Environment setup complete")
    }
    
    func setupAttachments(in environment: Entity, for portal: Entity, titleEntity: Entity? = nil, labViewerEntity: Entity? = nil) {
        // Separate logo setup
        if let l = environment.findEntity(named: "logo") {
            Logger.debug("🔍 Found logo: \(l.name)")
            logo = l
            l.scale = SIMD3<Float>(0.5, 0.5, 0.5)
            l.opacity = 0
            Logger.debug("✅ Set logo scale to 0.5 and opacity to 0")
        } else {
            Logger.error("❌ Logo entity not found during setup")
        }
        
        // Separate title setup
        if let title = environment.findEntity(named: "outdoCancer") {
            Logger.debug("Found title: \(title.name)")
            titleRoot = title
            title.opacity = 0
            Logger.debug("Set title opacity to 0")
        } else {
            Logger.error("❌ Title entity not found during setup")
        }
    }
    
    // MARK: - Private Setup Methods
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
    
    private func setupPortal(in root: Entity) async {
        Logger.debug("📱 IntroViewModel: Starting portal setup")
        do {
            // Load assembled lab using loadAssembledLab
            let labEnvironment = try await appModel.assetLoadingManager.loadAssembledLab()
            Logger.debug("✅ IntroViewModel: Successfully loaded assembled laboratory environment")
            
            assembledLab = labEnvironment
            assembledLab?.name = "assembled_lab"
            
            // Create portal with loaded environment
            let p = await PortalManager.createPortal(
                appModel: appModel,
                environment: labEnvironment,
                portalPlaneName: "Plane_001"
            )
            Logger.debug("✅ IntroViewModel: Created portal")
            
            // Store and configure portal
            portal = p
            p.opacity = 0.0
            p.position = [0, -0.25, 0]
            root.addChild(p)
            
            // Ensure the ADC template is up-to-date in labState before setting up ADCs
            if appModel.hasBuiltADC && appModel.gameState.adcTemplate != nil {
                Logger.debug("🔄 Updating labState.adcTemplate with latest custom ADC")
                appModel.labState.adcTemplate = appModel.gameState.adcTemplate
            }
            
            Logger.debug("Attempting to setup interactive ADC for user")
            await appModel.labState.setupADCPlacer(in: root)
            await appModel.labState.setupExtraADCs(in: root)
            
            Logger.debug("✅ IntroViewModel: Portal setup complete")
            
        } catch {
            Logger.debug("❌ IntroViewModel: Failed to load laboratory environment: \(error)")
            // Handle specific error cases
            if let assetError = error as? AssetError {
                switch assetError {
                case .resourceNotFound:
                    Logger.debug("❌ IntroViewModel: Lab environment resource not found")
                case .protobufError(let name):
                    Logger.debug("❌ IntroViewModel: Protobuf error loading lab environment: \(name)")
                default:
                    Logger.debug("❌ IntroViewModel: Asset error loading lab environment: \(assetError)")
                }
            }
        }
    }
    
    
    // MARK: - Animation Methods
    func runAnimationSequence() async {
        // // Request head position update before starting animation sequence
        // shouldUpdateHeadPosition = true
        
        // Cancel any existing animation task
        animationTask?.cancel()
        
        // Create new animation task
        animationTask = Task { @MainActor in
            let start = Date()
            Logger.debug("🎬 Animation Sequence: Starting at \(start)")
            Logger.debug("🔍 Entity Check - skyDome: \(skyDome != nil), logo: \(logo != nil), portal: \(portal != nil)")
            
            // Example helper guard to ensure an entity is still in the scene (if needed)
            @MainActor
            func ensureValidEntity(_ entity: Entity?, with name: String) -> Bool {
                if let e = entity, e.parent != nil {
                    return true
                } else {
                    Logger.debug("⚠️ Entity \(name) is no longer valid or not attached.")
                    return false
                }
            }
            
            // Check for cancellation before each animation step
            guard !Task.isCancelled else {
                Logger.debug("🛑 Animation sequence cancelled before sky fade")
                return
            }
            
            // Sky fade animation
            if shouldUseSky {
                Logger.debug("🌌 Sky: Starting at +\(Date().timeIntervalSince(start))s")
                if let s = skyDome {
                    Logger.debug("🔍 Sky initial opacity: \(s.opacity)")
                    await s.fadeOpacity(to: skyDarkness, duration: 10.0)
                    Logger.debug("🌌 Sky: Completed fade animation")
                } else {
                    Logger.debug("❌ Sky: skyDome not found")
                }
            }
            
            // Portal warp fade (24s)
            Logger.debug("⏰ Sleeping for 29s before portal warp")
            try? await Task.sleep(for: .seconds(29)) // changed from 19 to 29 since removed portalWarp
            
            guard !Task.isCancelled else {
                Logger.debug("🛑 Animation sequence cancelled before logo")
                return
            }
            
            // Logo and title sequence
            Logger.debug("⏰ Sleeping for 58s before logo")
            try? await Task.sleep(for: .seconds(58))
            
            // Verify both entities before starting animation sequence
            guard ensureValidEntity(logo, with: "logo") else {
                Logger.error("❌ Logo entity not valid or missing before animation")
                return
            }
            guard ensureValidEntity(titleRoot, with: "title") else {
                Logger.error("❌ Title entity not valid or missing before animation")
                return
            }
            
            Logger.debug("🎯 Logo and Title Sequence: Starting at +\(Date().timeIntervalSince(start))s")
            
            if let l = logo, let t = titleRoot {
                // Start logo animation
                Logger.debug("🔍 Logo initial state - opacity: \(l.opacity), scale: \(l.scale)")
                let logoAnimation = Task {
                    await l.fadeOpacity(to: 1.0, duration: 5.0)
                    Logger.debug("✨ Logo fade completed - final opacity: \(l.opacity)")
                }
                
                // Wait for logo animation and delay
                await logoAnimation.value
                Logger.debug("⏰ Waiting 5s before title animation")
                try? await Task.sleep(for: .seconds(5))
                
                // Start title animation
                Logger.debug("🔍 Title initial state - opacity: \(t.opacity)")
                
                // Set showTitleText to true to trigger the OutdoCancer animation
                showTitleText = true
                Logger.debug("✅ Set showTitleText to true, triggering OutdoCancer animation")
                
                let titleAnimation = Task {
                    await t.fadeOpacity(to: 1.0, duration: 5.0)
                    Logger.debug("✨ Title fade completed - final opacity: \(t.opacity)")
                }
                
                // Wait for title animation to complete
                await titleAnimation.value
                Logger.debug("✅ Logo and Title sequence complete")
                
            } else {
                Logger.error("❌ Logo or Title entity became invalid during animation sequence")
            }
            
            guard !Task.isCancelled else {
                Logger.debug("🛑 Animation sequence cancelled before portal")
                return
            }
            
            // Portal sequence
            Logger.debug("🌐 Portal: Starting at +\(Date().timeIntervalSince(start))s")
            guard ensureValidEntity(portal, with: "portal") else { return }
            Logger.debug("🔍 Portal reference check: \(portal != nil)")
            if let p = portal {
                Logger.debug("🔍 Portal initial opacity: \(p.opacity)")
                await p.fadeOpacity(to: 1.0, duration: 5.0)
                Logger.debug("🌐 Portal: Completed fade animation")
                Logger.debug("🔍 Portal final opacity: \(p.opacity)")
                try? await Task.sleep(for: .seconds(5.0))
                
                // Perform the original portalPlane X-scale animation
                if let portalPlane = p.findEntity(named: "portalPlane") {
                    Logger.debug("🌐 Portal plane: Starting X scale animation at +\(Date().timeIntervalSince(start))s")
                    await portalPlane.animateXScale(from: 0, to: 1.0, duration: 1.0)
                    Logger.debug("🌐 Portal plane: Completed X scale animation")
                } else {
                    Logger.debug("❌ Portal plane: portalPlane not found")
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
                    Logger.debug("❌ One or more entities for concurrent animations not found.")
                    if p.findEntity(named: "portalRoot") == nil {
                        Logger.debug("❌ PortalRoot not found")
                    }
                    if p.findEntity(named: "world") == nil {
                        Logger.debug("❌ World not found")
                    }
                    if p.findEntity(named: "portalPlane") == nil {
                        Logger.debug("❌ PortalPlane not found")
                    }
                    return
                }

                Logger.debug("🌐 Starting concurrent animations for PortalRoot, World, and PortalPlane scale")
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
                
                Logger.debug("🌐 Completed concurrent animations for PortalRoot, World, and PortalPlane scale")
                

                // Wait for 5 seconds
                try? await Task.sleep(for: .seconds(8))
                
                // Unparent the portalWorld from the portal and reparent it to the root while preserving its transform
                if let lab = assembledLab {
                    // Capture the current transform of the lab in world space
                    let worldTransform = lab.transformMatrix(relativeTo: nil)
                    
                    // Remove the lab from its current parent
                    lab.removeFromParent()
                    
                    // Reparent the lab to the intro root entity
                    introRootEntity!.addChild(lab)
                    Logger.debug("🛑 assembledLab position in world space PRE-TRANSFORM FIX is \(lab.position(relativeTo: nil))")
                    
                    // Restore the lab's transform
                    lab.setTransformMatrix(worldTransform, relativeTo: nil)
                    Logger.debug("✅ assembledLab position in world space is \(lab.position(relativeTo: nil))")
                }

                // Change the portal component to spill out into the world
                if var portalComponent = portalPlane2.components[PortalComponent.self] {
                    portalComponent.crossingMode = .plane(.positiveZ)
                    portalPlane2.components.set(portalComponent)
                } else {
                    Logger.debug("❌ PortalComponent not found on portalPlane2.")
                }
                
                if let portalEnv = self.portal {
                    Logger.debug("\n 🔍 Inspecting portal hierarchy \n")
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
                Logger.debug("❌ Portal: portal not found")
            }
            
            Logger.debug("🎬 Animation Sequence: Completed at +\(Date().timeIntervalSince(start))s")
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
        startButtonPressed = false
        
        appModel.readyToStartLab = false
        
        Logger.debug("✅ Completed IntroViewModel cleanup\n")
    }
    
    private func applyMeshSorting(from parent: Entity, to child: Entity) {
        // Old helper remains in case it's needed elsewhere
        if let sortingComponent = parent.components[ModelSortGroupComponent.self] {
            child.components.set(sortingComponent)
            Logger.debug("✅ Applied ModelSortGroupComponent from \(parent.name) to \(child.name)")
        } else {
            Logger.debug("❌ No ModelSortGroupComponent found on \(parent.name) to apply to \(child.name)")
        }
    }

    // MARK: FADE OUT SCENE
    /// Fades out the entire scene gracefully
    /// - Returns: Void
    @MainActor
    func fadeOutScene() async {
        Logger.info("🎬 Starting scene fade out")
        
        guard let root = introRootEntity else {
            Logger.debug("⚠️ No root entity found for fade out")
            return
        }
        
        await root.fadeOpacity(
            to: 0.0,
            duration: 2.0,
            timing: .easeInOut,
            waitForCompletion: true
        )
        
        Logger.info("✨ Scene fade out complete")
    }
}
