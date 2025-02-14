import SwiftUI
import RealityKit
import RealityKitContent


struct AttackCancerView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.realityKitScene) private var scene
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        @Bindable var appModel = appModel
        
        RealityView { content, attachments in
            print("\n=== AttackCancerView Setup ===")
            print("📱 AttackCancerView: Setting up root")
            let root = appModel.gameState.setupRoot()
            root.name = "AttackCancerRoot"
            print("✅ Root entity created: \(root.name)")

            // let decoy = Entity()
            // decoy.name = "Decoy"
            // decoy.components.set(PositioningComponent(
            //     offsetX: 0,
            //     offsetY: 0,
            //     offsetZ: -1.0
            // ))
            // root.addChild(decoy)
            // print("✅ Decoy entity added to root")
            
            content.add(root)
            appModel.gameState.storedAttachments = attachments
            appModel.gameState.setupHandTracking(in: content, attachments: attachments)
            
            // Setup environment in a task after root is configured
            Task { @MainActor in
                print("\n=== Setting up Environment ===")
                await appModel.gameState.setupEnvironment(in: root, attachments: attachments)
                print("✅ Environment setup complete")
                
                // If tutorial is already started, begin it
                if appModel.isTutorialStarted {
                    print("\n🎓 Starting tutorial sequence...")
                    await appModel.gameState.startTutorial(in: root, attachments: attachments)
                }
                
                // If game should start, handle it
                if appModel.shouldStartGame {
                    await appModel.gameState.handleGameStart(in: root)
                }
            }
        } attachments: {

        }
        .task {
            await appModel.trackingManager.processWorldTrackingUpdates()
        }
        .task {
            await appModel.trackingManager.processHandTrackingUpdates()
        }
        .task {
            await appModel.trackingManager.monitorTrackingEvents()
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    // Allow taps either if the game is running or if we're active in the test fire phase.
                    if appModel.gameState.isHopeMeterRunning || appModel.gameState.isTestFireActive {
                        let location3D = value.convert(value.location3D, from: .local, to: .scene)
                        appModel.gameState.totalTaps += 1
                        
                        Task {
                            await appModel.gameState.handleTap(on: value.entity, location: location3D, in: scene)
                        }
                    }
                }
        )
        .onChange(of: scenePhase) { _, newPhase in
            // Let the app handle scene phase changes
        }
        .onChange(of: appModel.isHopeMeterUtilityWindowOpen) { _, isOpen in
            print("onChange: isHopeMeterUtilityWindowOpen changed to \(isOpen)")
            if isOpen {
                openWindow(id: AppModel.hopeMeterUtilityWindowId)
                print("🎮 Setting up cancer cells")
                if let root = appModel.gameState.rootEntity {
                    Task {
                        await appModel.gameState.setupGameContent(in: root)
                    }
                }
            }
        }
        .onAppear {
            dismissWindow(id: AppModel.navWindowId)
        }
        .onDisappear {
            // Only perform teardown if not transitioning to a preserving state (e.g., .completed)
            if appModel.currentPhase != .completed {
                Task {
                    await appModel.gameState.tearDownGame()
                }
            } else {
                print("🚫 Skipping tearDownGame() for completed phase to preserve immersive assets")
            }
        }
        .onChange(of: appModel.isTutorialStarted) { _, started in
            // Only start tutorial if it wasn't already started during initial setup
            if started && !appModel.gameState.isSetupComplete,
               let root = appModel.gameState.rootEntity,
               let attachments = appModel.gameState.storedAttachments {
                print("🎓 Tutorial state changed - Starting tutorial...")
                Task {
                    await appModel.gameState.startTutorial(in: root, attachments: attachments)
                }
            }
        }
        .onChange(of: appModel.shouldStartGame) { _, shouldStart in
            if shouldStart, let root = appModel.gameState.rootEntity {
                Task {
                    await appModel.gameState.handleGameStart(in: root)
                }
            }
        }
    }
}
