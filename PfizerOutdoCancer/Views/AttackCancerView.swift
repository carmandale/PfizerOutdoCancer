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
            appModel.gameState.resetGameState()
            Logger.info("🔄 Reset game state")
            Logger.info("\n=== AttackCancerView Setup ===")
            Logger.info("📱 AttackCancerView: Setting up root")
            let root = appModel.gameState.setupRoot()
            root.name = "AttackCancerRoot"
            Logger.info("✅ Root entity created: \(root.name)")
            
            content.add(root)
            appModel.gameState.storedAttachments = attachments
            appModel.gameState.setupHandTracking(in: content, attachments: attachments)
            
            // Setup environment in a task after root is configured
            Task { @MainActor in
                Logger.info("\n=== Setting up Environment ===")
                await appModel.gameState.setupEnvironment(in: root, attachments: attachments)
                Logger.info("✅ Environment setup complete")
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
                    if appModel.gameState.isGameActive || appModel.gameState.isTestFireActive {
                        let location3D = value.convert(value.location3D, from: .local, to: .scene)
                        appModel.gameState.totalTaps += 1
                        
                        Task {
                            await appModel.gameState.handleTap(on: value.entity, location: location3D, in: scene)
                        }
                    }
                }
        )
        .onChange(of: appModel.gameState.shouldPlayStartButtonVO) { _, isReady in
            Logger.info("onChange: readyToStartGame changed to \(isReady)")
            if isReady {
                if let root = appModel.gameState.rootEntity {
                    Task {
                        // wait just a little to give it a breath...
                        try? await Task.sleep(for: .milliseconds(300))

                        Logger.info("\n>>> Playing start button VO...\n")
                        await appModel.gameState.playStartButtonVO(in: root)
                        
                        self.appModel.isHopeMeterUtilityWindowOpen = true
                        Logger.info("Hope meter utility window open = \(self.appModel.isHopeMeterUtilityWindowOpen)")
                    }
                    
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Let the app handle scene phase changes
        }
        .onChange(of: appModel.isHopeMeterUtilityWindowOpen) { _, isOpen in
            Logger.info("onChange: isHopeMeterUtilityWindowOpen changed to \(isOpen)")
            if isOpen {
                openWindow(id: AppModel.hopeMeterUtilityWindowId)
                Logger.info("🎮 Setting up cancer cells")
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
                Logger.info("🚫 Skipping tearDownGame() for completed phase to preserve immersive assets")
            }
        }
        .onChange(of: appModel.shouldStartGame) { _, shouldStart in
            if shouldStart, let root = appModel.gameState.rootEntity {
                Task {
                    await appModel.gameState.handleGameStart(in: root)
                }
            }
        }
        .onChange(of: appModel.gameState.shouldUpdateHeadPosition) { _, shouldUpdate in
            if shouldUpdate && appModel.gameState.isReadyForInteraction {
                if let root = appModel.gameState.rootEntity,
                   let headTrackingRoot = root.findEntity(named: "headTrackingRoot") {
                    Logger.info("""
                    
                    🎯 Head Position Update Requested
                    ├─ Phase: \(appModel.currentPhase)
                    ├─ Current World Position: \(headTrackingRoot.position(relativeTo: nil))
                    ├─ Root Setup: \(appModel.gameState.isRootSetupComplete ? "✅" : "❌")
                    ├─ Environment: \(appModel.gameState.isEnvironmentSetupComplete ? "✅" : "❌")
                    └─ HeadTracking: \(appModel.gameState.isHeadTrackingRootReady ? "✅" : "❌")
                    """)
                    
                    Task {
                        headTrackingRoot.checkHeadPosition(animated: true, duration: 0.5)
                        appModel.gameState.shouldUpdateHeadPosition = false
                        appModel.gameState.isPositioningComplete = true  // Set after animation completes
                    }
                }
            }
        }
        .onChange(of: appModel.gameState.isPositioningComplete) { _, complete in
            if complete {
                Task { @MainActor in
                    // If tutorial should start, start it now
                    if appModel.isTutorialStarted && !appModel.gameState.isSetupComplete,
                       let root = appModel.gameState.rootEntity,
                       let attachments = appModel.gameState.storedAttachments {
                        Logger.info("🎓 Starting tutorial after positioning complete...")
                        await appModel.gameState.startTutorial(in: root, attachments: attachments)
                    }
                }
            }
        }
        .onChange(of: appModel.gameState.isHopeMeterRunning) { _, isRunning in
            if !isRunning {
                Logger.info("Hope meter stopped - closing utility window")
                dismissWindow(id: AppModel.hopeMeterUtilityWindowId)
                appModel.isHopeMeterUtilityWindowOpen = false
            }
        }
    }
}
