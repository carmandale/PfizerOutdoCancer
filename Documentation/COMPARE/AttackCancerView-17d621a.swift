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
            print("📱 AttackCancerView: Setting up RealityView")
            let root = appModel.gameState.setupRoot()
            
            content.add(root)
            
            appModel.gameState.storedAttachments = attachments
            
            // Store attachments for later setup
//            if let hopeMeterEntity = attachments.entity(for: "HopeMeter") {
//                print("📱 AttackCancerView: Found SwiftUI attachments")
//                
//            } else {
//                print("❌ AttackCancerView: Failed to get SwiftUI attachments")
//            }
            
            appModel.gameState.setupHandTracking(in: content, attachments: attachments)
        } attachments: {
            // HopeMeter attachment
            // Attachment(id: "HopeMeter") {
            //     HopeMeterView()
            // }
            
            // Cell counter attachments
//            ForEach(0..<appModel.gameState.maxCancerCells, id: \.self) { i in
//                Attachment(id: "\(i)") {
//                    if i < cellStates.count {
//                        HitCounterView(
//                            hits: cellStates[i].hits,
//                            requiredHits: cellStates[i].requiredHits,
//                            isDestroyed: cellStates[i].isDestroyed
//                        )
//                    } else {
//                        HitCounterView(hits: 0, requiredHits: 0, isDestroyed: false)
//                    }
//                }
//            }
        }
        .task(id: appModel.gameState.rootEntity) {
            guard !appModel.gameState.isSetupComplete else {
                print("📱 AttackCancerView: Setup already complete, skipping")
                return
            }
            
            guard let root = appModel.gameState.rootEntity else {
                print("❌ AttackCancerView: No root entity found in task")
                return
            }
            
            guard let attachments = appModel.gameState.storedAttachments else {
                print("❌ AttackCancerView: No stored attachments found")
                return
            }
            
            print("📱 AttackCancerView: Starting environment setup")
            await appModel.gameState.setupEnvironment(in: root, attachments: attachments)
            
            // Start tracking systems
            await appModel.trackingManager.processWorldTrackingUpdates()
            await appModel.trackingManager.processHandTrackingUpdates()
            await appModel.trackingManager.monitorTrackingEvents()
            
            appModel.gameState.isSetupComplete = true
            print("✅ AttackCancerView: Setup complete")
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    // Check if this is first tap and hope meter hasn't started
                    if appModel.gameState.totalTaps == 0 && appModel.isHopeMeterUtilityWindowOpen {
                        appModel.startAttackCancerGame()
                    }
                    
                    // Only handle taps if game is running
                    if appModel.gameState.isHopeMeterRunning {
                        let location3D = value.convert(value.location3D, from: .local, to: .scene)
                        appModel.gameState.totalTaps += 1
                        
                        Task {
                            await appModel.gameState.handleTap(on: value.entity, location: location3D, in: scene)
                        }
                    }
                }
        )
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive {
                appModel.gameState.tearDownGame()
            }
        }
        .onChange(of: appModel.isHopeMeterUtilityWindowOpen) { _, isOpen in
            if isOpen {
                openWindow(id: AppModel.hopeMeterUtilityWindowId)
            }
        }
        .onAppear {
            dismissWindow(id: AppModel.navWindowId)
        }
        .onDisappear {
            appModel.gameState.tearDownGame()
        }
        .onChange(of: appModel.isTutorialStarted) { _, started in
            if started, let root = appModel.gameState.rootEntity, let attachments = appModel.gameState.storedAttachments {
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
