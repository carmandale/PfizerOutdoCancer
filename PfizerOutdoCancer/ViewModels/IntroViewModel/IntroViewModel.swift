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
    
    // Animation task tracking
    private var animationTask: Task<Void, Never>?
    
    // Entity references
    private var portalWarp: Entity?
    private var portal: Entity?
    private var skyDome: Entity?
    private var logo: Entity?
    private var titleRoot: Entity?
    private var material: ShaderGraphMaterial?
    private var assembledLab: Entity?
    private var introEnvironment: Entity?
    
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
    
    // MARK: - Setup Methods
    func setupIntroRoot() -> Entity {
        print("📱 IntroViewModel: Setting up intro root")
        let root = Entity()
        root.name = "IntroRoot"
        introRootEntity = root
        return root
    }
    
    // MARK: - Setup Environment
    func setupEnvironment(in root: Entity) async {
        print("📱 IntroViewModel: Starting environment setup")
        
        // Set up hand tracking
//        let handTrackingEntity = appModel.trackingManager.handTrackingManager.setupContentEntity()
//        root.addChild(handTrackingEntity)
        
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
            introEnvironment = environment
            print("📱 IntroViewModel: Adding environment to root")
            root.addChild(environment)
        } catch {
            print("❌ IntroViewModel: Error loading intro environment: \(error)")
            return
        }
        
//       var lab: Entity
//       do {
//           lab = try await appModel.assetLoadingManager.instantiateAsset(withName: "assembled_lab", category: AssetCategory.introEnvironment)
//           print("✅ Assembled lab found")
//           assembledLab = lab
////           lab.position.z -= 0.25
////           lab.position.y -= 1.425
//           lab.opacity = 1
//           lab.isEnabled = false
//           root.addChild(lab)
//           print("📱 IntroViewModel: Adding lab to root")
//           
//       } catch {
//           print("❌ Assembled lab not found: Error loading assembled lab: \(error)")
//           return
//       }
        
        // Find and setup entities
        print("📱 IntroViewModel: Setting up individual entities")
        // setupSkyDome(in: environment)
        // setupLogo(in: environment)
        await setupPortalWarp(in: environment)
        await setupPortal(in: root)
        
        print("✅ IntroViewModel: Environment setup complete")
    }
    
    func setupAttachments(in environment: Entity, for portal: Entity, titleEntity: Entity, labViewerEntity: Entity? = nil) {
        if let l = environment.findEntity(named: "logo") {
                print("🔍 Found logo: \(l.name)")
                logo = l
                l.scale = SIMD3<Float>(0.5, 0.5, 0.5)
                l.opacity = 0
                print("✅ Set logo scale to 0.5 and opacity to 0")

                // Add text attachment to titleRoot
                if let t = portal.findEntity(named: "titleRoot") {
                titleRoot = t
                print("📎 Created titleRoot")
                // print("🔍 Before - titleEntity position: \(titleEntity.position), scale: \(titleEntity.transform.scale)")
                titleEntity.position = [0, -1.2, 0.1]
                titleEntity.transform.scale *= 10.0
                print("🔍 After - titleEntity position: \(titleEntity.position), scale: \(titleEntity.transform.scale)")
                t.addChild(titleEntity)

                // labViewerEntity.position = [0, -1.0, 0.2]
                // labViewerEntity.transform.scale *= 5.0
                // print("🔍 After - labViewer position: \(labViewerEntity.position), scale: \(labViewerEntity.transform.scale)")
                // t.addChild(labViewerEntity)
                // print("📎 Added labViewer to titleRoot")

                l.addChild(t)
                print("📎 Added titleText to titleRoot")

            } else {
                print("❌ Could not find logo in environment")
            }
        }
    }

    private func setupLogo(in environment: Entity, titleEntity: Entity, labViewerEntity: Entity) {
        
    }
    
    // MARK: - Private Setup Methods
    private func setupSkyDome(in environment: Entity) {
        // if let sky = environment.findEntity(named: "SkySphere") {
        //     print("🔍 Found skyDome: \(sky.name)")
        //     skyDome = sky
        //     sky.opacity = 0
        //     print("✅ Set skyDome opacity to 0")
        // } else {
        //     print("❌ Could not find SkySphere in environment")
        // }
    }
    
    private func setupPortalWarp(in environment: Entity) async {
        if let warp = environment.findEntity(named: "sh0100_v01_portalWarp3") {
            print("🔍 Found portalWarp: \(warp.name)")
            portalWarp = warp
            warp.opacity = 0
            print("✅ Set portalWarp opacity to \(warp.opacity)")
            
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
            
            assembledLab = labEnvironment
            assembledLab?.name = "assembled_lab"
            
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
    
    // MARK: - Positioning Refresh
    /// Refreshes the position of the introRootEntity based on the current device anchor.
    /// Called at the moment the user starts the animation sequence.
    private func refreshPosition() async {
        guard let root = introRootEntity else {
            print("❌ refreshPosition: introRootEntity is nil.")
            return
        }

        guard let posComponent = root.components[PositioningComponent.self] else {
            print("❌ refreshPosition: No PositioningComponent on introRootEntity.")
            return
        }

        // Query the device anchor from the tracking manager.
        guard let deviceAnchor = appModel.trackingManager.worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else {
            print("❌ refreshPosition: Device anchor unavailable. Using fallback position.")
            let fallback = SIMD3<Float>(posComponent.offsetX, posComponent.offsetY, posComponent.offsetZ)
            root.setPosition(fallback, relativeTo: nil)
            return
        }

        let deviceTransform = deviceAnchor.originFromAnchorTransform
        let translation = deviceTransform.translation()
        let translationLength = simd_length(translation)

        // Check if the translation seems valid.
        if translationLength < 0.01 {
            print("❌ refreshPosition: Device translation too small (\(translation)). Using fallback.")
            let fallback = SIMD3<Float>(posComponent.offsetX, posComponent.offsetY, posComponent.offsetZ)
            root.setPosition(fallback, relativeTo: nil)
            return
        }

        if translationLength > 10.0 {
            print("❌ refreshPosition: Device translation unusually high (\(translation)). Using fallback.")
            let fallback = SIMD3<Float>(posComponent.offsetX, posComponent.offsetY, posComponent.offsetZ)
            root.setPosition(fallback, relativeTo: nil)
            return
        }

        // Compute the final position using the offsets from PositioningComponent.
        let newPosition = SIMD3<Float>(
            translation.x + posComponent.offsetX,
            translation.y + posComponent.offsetY,
            translation.z + posComponent.offsetZ
        )
        root.setPosition(newPosition, relativeTo: nil)
        print("✅ refreshPosition: Updated introRootEntity position to \(newPosition)")

        // Optionally mark as positioned to prevent further automatic updates.
        var updatedComponent = posComponent
        updatedComponent.needsPositioning = false
        root.components[PositioningComponent.self] = updatedComponent
    }

    // Refresh the position at the moment the user initiates the animation sequence.
            // await refreshPosition()
    
    // MARK: - Animation Methods
    func runAnimationSequence() async {
        // Cancel any existing animation task
        animationTask?.cancel()
        
        // Create new animation task
        animationTask = Task { @MainActor in
            let start = Date()
            print("🎬 Animation Sequence: Starting at \(start)")
            print("🔍 Entity Check - skyDome: \(skyDome != nil), portalWarp: \(portalWarp != nil), logo: \(logo != nil), portal: \(portal != nil)")
            
            // Check for cancellation before each animation step
            guard !Task.isCancelled else {
                print("🛑 Animation sequence cancelled before sky fade")
                return
            }
            
            guard !Task.isCancelled else {
                print("🛑 Animation sequence cancelled before portal warp")
                return
            }
            
            // Portal warp fade (24s)
            print("⏰ Sleeping for 19s before portal warp")
            try? await Task.sleep(for: .seconds(19))
            print("🌀 Portal warp: Starting at +\(Date().timeIntervalSince(start))s")
            print("🔍 PortalWarp reference check: \(portalWarp != nil)")
            if let warp = portalWarp {
                print("🔍 Warp initial opacity: \(warp.opacity)")
                await warp.fadeOpacity(to: 0.5, duration: 10.0)
                print("🌀 Portal warp: Completed fade animation")
                print("🔍 Warp final opacity: \(warp.opacity)")
            } else {
                print("❌ Portal warp: portalWarp not found")
            }
            
            guard !Task.isCancelled else {
                print("🛑 Animation sequence cancelled before logo")
                return
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
            
            guard !Task.isCancelled else {
                print("🛑 Animation sequence cancelled before portal")
                return
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
                
                // Perform the original portalPlane X-scale animation
                if let portalPlane = p.findEntity(named: "portalPlane") {
                    print("🌐 Portal plane: Starting X scale animation at +\(Date().timeIntervalSince(start))s")
                    await portalPlane.animateXScale(from: 0, to: 1.0, duration: 1.0)
                    print("🌐 Portal plane: Completed X scale animation")
                } else {
                    print("❌ Portal plane: portalPlane not found")
                }

                // Wait 2 seconds after portalPlane animation finishes
                try? await Task.sleep(for: .seconds(2.0))

            

                if let portalRoot = p.findEntity(named: "portalRoot"),
                   let portalWorld = p.findEntity(named: "world"),
                   let portalPlane2 = p.findEntity(named: "portalPlane"),
                   let warp = portalWarp,
                   let introEnv = introEnvironment,
                   let root = introRootEntity,
                   let extras = root.findEntity(named: "ExtraItems"),
                   let logoFadeOut = logo,
                   let titleRootFadeOut = titleRoot
                {
                    print("🌐 Starting concurrent animations for PortalRoot, World, and PortalPlane scale")
                    let moveDuration = 20.0
                    
                    async let _: () = warp.fadeOpacity(
                        to: 0.0,
                        duration: 10.0
                    )
                    
                    async let _: () = logoFadeOut.fadeOpacity(
                        to: 0.0,
                        duration: 3.0
                    )
                    async let _: () = titleRootFadeOut.fadeOpacity(
                        to: 0.0,
                        duration: 3.0
                    )
//                    async let animateOutTitle = withAnimation { showTitleText = false }

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
                    
                    print("🌐 Completed concurrent animations for PortalRoot, World, and PortalPlane scale")
                    
                    // fade out the introEnvironment
                    print("introEnvironment opacity started at \(introEnv.opacity)")
                    await introEnv.fadeOpacity(to: 0.0, duration: 5.0)
                    print("introEnvironment opacity faded out to \(introEnv.opacity)")

                    // wait for 5 seconds
                    try? await Task.sleep(for: .seconds(5))

                    
                    
                    // unparent the portalWorld from the portal and reparent it to the root while keeping its transform
                    let worldTransform = portalWorld.transformMatrix(relativeTo: nil)
                    portalWorld.removeFromParent()
                    root.addChild(portalWorld)
                    print("🛑 portalWorld position in world space PRE-TRANSFORM FIX is \(portalWorld.position(relativeTo: nil))")
                    portalWorld.setTransformMatrix(worldTransform, relativeTo: nil)
                    print("✅ portalWorld position in world space is \(portalWorld.position(relativeTo: nil))")

                    // change the portal component to all the lab to spill out into the world
                    if var portalComponent = portalPlane2.components[PortalComponent.self] {
                        // Update the portal component's properties to "spill out"
                        portalComponent.crossingMode = .plane(.positiveZ)
                        // Reassign the updated component back to the entity
                        portalPlane2.components.set(portalComponent)
                    } else {
                        print("❌ PortalComponent not found on portalPlane2.")
                    }

                    // print( "portalWorld parented to root")
//                    introEnv.isEnabled = false
//                    appModel.assetLoadingManager.inspectEntityHierarchy(introEnv)
                    extras.isEnabled = false
                    print("disabled extras in intro environment")
                    
                    // wait a little for the audio to finish before removing things
                    try? await Task.sleep(for: .seconds(8))

                    // Clean up audio entities
                    if let audioEntity = introEnv.findEntity(named: "Audio") {
                        print("🔊 Found Audio entity, beginning cleanup")
                        
                        // Recursively remove components from children first
                        for child in audioEntity.children {
                            child.components.removeAll()
                            child.removeFromParent()
                        }
                        
                        // Remove all components from audio entity
                        audioEntity.components.removeAll()
                        
                        // Remove from parent
                        audioEntity.removeFromParent()
                        
                        print("✅ Audio entity cleanup complete")
                    }

                    // Clean up extra items
                    if let extrasEntity = root.findEntity(named: "ExtraItems") {
                        print("🧹 Found ExtraItems entity, beginning cleanup")
                        
                        // Recursively remove components from children first
                        for child in extrasEntity.children {
                            child.components.removeAll()
                            child.removeFromParent()
                        }
                        
                        // Remove all components from extras entity
                        extrasEntity.components.removeAll()
                        
                        // Remove from parent
                        extrasEntity.removeFromParent()
                        
                        print("✅ ExtraItems cleanup complete")
                    }
                    
                    // Enable the large room reverb effect when entering a new room
                    root.enableLargeRoomReverb()
                    appModel.assetLoadingManager.inspectEntityHierarchy(root)

                    // ready to readyToStartLab
                    appModel.readyToStartLab = true
                    print("readyToStartLab set to \(appModel.readyToStartLab)")

                } else {
                    print("❌ One or more entities for concurrent animations not found:")
                    if p.findEntity(named: "portalRoot") == nil {
                        print("❌ PortalRoot not found")
                    }
                    if p.findEntity(named: "world") == nil {
                        print("❌ World not found")
                    }
                    if p.findEntity(named: "portalPlane") == nil {
                        print("❌ PortalPlane not found")
                    }
                }
            } else {
                print("❌ Portal: portal not found")
            }
            
            
            
            print("🎬 Animation Sequence: Completed at +\(Date().timeIntervalSince(start))s")
        }
    }
    
    // MARK: - Entity Access Methods
    func getPortal() -> Entity? {
        return portal
    }
    
    // MARK: - Cleanup
    func cleanup() {
        print("\n=== Starting IntroViewModel Cleanup ===")
        
        // First, cancel any running animation task
        print("🛑 Cancelling animation sequence")
        animationTask?.cancel()
        animationTask = nil
        
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
        navToggleEntity = nil
        
        // Reset state flags
        showTitleText = false
        shouldDimSurroundings = false
        isSetupComplete = false
        environmentLoaded = false
        
        print("✅ Completed IntroViewModel cleanup\n")
    }
}
