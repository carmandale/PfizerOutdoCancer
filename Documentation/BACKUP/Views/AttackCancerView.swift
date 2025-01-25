import SwiftUI
import RealityKit
import RealityKitContent

struct CellState {
    var hits: Int = 0
    var requiredHits: Int = 0
    var isDestroyed: Bool = false
}

struct AttackCancerView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.realityKitScene) private var scene
    @State private var cellStates: [CellState] = []
    @State var immersionAmount: Float = 0
    
    // 1. Hand tracking entity setup
    @State private var handTrackedEntity: Entity? = nil
    
// Store attachments reference
    
    @Environment(\.openWindow) private var openWindow
    
    
    // Add near other @State properties
    @State private var tutorialCancerCell: Entity?
    
    // Add after other private properties
    private let tutorialADCDelays: [TimeInterval] = [
        2.0,  // First ADC at 2s
        1.9,  // Second ADC at 3.9s
        1.9,  // Third ADC at 5.8s
        1.9,  // Fourth ADC at 7.7s
        1.9,  // Fifth ADC at 9.6s
        1.9,  // Sixth ADC at 11.5s
        1.9,  // Seventh ADC at 13.4s
        1.9,  // Eighth ADC at 15.3s
        1.9,  // Ninth ADC at 17.2s
        1.8   // Tenth ADC at 19s
    ]
    
    var body: some View {
        RealityView { content, attachments in
            let root = appModel.gameState.setupRoot()
            root.name = "AttackCancerRoot"

            let decoy = Entity()
            decoy.name = "Decoy"
            root.addChild(decoy)    
            
            // Add PositioningComponent to keep world tracking active
            decoy.components.set(PositioningComponent(
                offsetX: 0,
                offsetY: 0,
                offsetZ: -1.0
            ))
            
            content.add(root)
            appModel.gameState.rootEntity = root
            appModel.gameState.storedAttachments = attachments  // Store attachments for later use
            
            setupHandTracking(in: content, attachments: attachments)
            

            // Initial environment setup only
            Task {
                print("🎯 Setting up AttackCancerView environment...")
                await setupEnvironment(in: root)
                print("✅ Environment setup complete")
            }
            
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
        .gesture(makeTapGesture())
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive {
                appModel.gameState.tearDownGame()
            }
        }
        .onAppear {
            dismissWindow(id: AppModel.debugNavigationWindowId)
        }
        .onDisappear {
            appModel.gameState.tearDownGame()
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
        .onChange(of: appModel.isTutorialStarted) { _, started in
            if started, let root = appModel.gameState.rootEntity {
                print("🎓 Tutorial state changed - Starting tutorial...")
                Task {
                    await startTutorial(in: root)
                    
                    // Start 43s timer after tutorial starts
                    // print("⏱️ Starting 43 second timer for instructions...")
                    // try? await Task.sleep(for: .seconds(43))
                    // print("⏱️ Timer complete - Reopening instructions window")
                    // openWindow(id: AppModel.mainWindowId)
                    // appModel.isMainWindowOpen = true
                }
            }
        }
        .onChange(of: appModel.shouldStartGame) { _, shouldStart in
            if shouldStart, let root = appModel.gameState.rootEntity {
                // Fade out tutorial
                if let tutorialContent = root.findEntity(named: "Decoy") {
                    Task {
                        await tutorialContent.fadeOpacity(to: 0, duration: 1)
                    }
                }
            }
        }
    }
    
    // 4. Hand tracking setup method
    private func setupHandTracking(in content: RealityViewContent, attachments: RealityViewAttachments) {
        // Add the hand tracking content entity which includes the debug spheres
        content.add(appModel.trackingManager.handTrackingManager.setupContentEntity())
        
        // Create a separate anchor for the HopeMeter UI
        let uiAnchor = AnchorEntity(.hand(.left, location: .aboveHand))
        content.add(uiAnchor)
        
        // if let attachmentEntity = attachments.entity(for: "HopeMeter") {
        //     attachmentEntity.components[BillboardComponent.self] = BillboardComponent()
        //     attachmentEntity.scale *= 0.6
        //     attachmentEntity.position.z -= 0.02
        //     uiAnchor.addChild(attachmentEntity)
        // }
    }
    
    @MainActor
    private func setupGameContent(in root: Entity, attachments: RealityViewAttachments) async {
//        print("\n=== Initializing Cell States ===")
        cellStates = Array(repeating: CellState(), count: appModel.gameState.maxCancerCells)
        

        // ADC template is already set up during phase transition
        
        if let cancerCellTemplate = await appModel.assetLoadingManager.instantiateEntity("cancer_cell") {
            let maxCells = appModel.gameState.maxCancerCells
            await appModel.gameState.spawnCancerCells(in: root, from: cancerCellTemplate, count: maxCells)
//            setupUIAttachments(in: root, attachments: attachments, count: maxCells)
            
            // Update required hits and setup hit tracking
            for i in 0..<maxCells {
                if let cell = root.findEntity(named: "cancer_cell_\(i)")?.findEntity(named: "cancerCell_complex") {
                    // Set initial required hits
                    if let state = cell.components[CancerCellStateComponent.self] {
                        cellStates[i].requiredHits = state.parameters.requiredHits
//                        print("🎯 Counter \(i) ready: \(cellStates[i].hits)/\(cellStates[i].requiredHits)")
                    }
                    
                    // Setup hit tracking closure
                    cell.components.set(
                        ClosureComponent { [self] _ in
                            if let state = cell.components[CancerCellStateComponent.self] {
                                let oldHits = cellStates[i].hits
                                let wasDestroyed = cellStates[i].isDestroyed
                                
                                // Update state
                                cellStates[i].hits = state.parameters.hitCount
                                cellStates[i].isDestroyed = state.parameters.isDestroyed
                                
                                // Track stats
                                if !wasDestroyed && state.parameters.isDestroyed {
                                    appModel.gameState.cellsDestroyed += 1
//                                    print("💀 Cell \(i) destroyed - Total destroyed: \(appModel.gameState.cellsDestroyed)")
                                }
                                
                                // Only log actual changes
                                if oldHits != state.parameters.hitCount {
//                                    print("📊 Cell \(i): \(state.parameters.hitCount)/\(state.parameters.requiredHits) hits")
                                }
                            }
                        }
                    )
                }
            }
            
            // print("🎮 Game Content Setup Complete - Starting Hope Meter")
            // appModel.startHopeMeter()
        }
    }
    
    @MainActor
    private func setupEnvironment(in root: Entity) async {
        await appModel.gameState.setupEnvironment(in: root)
    }

    @MainActor
    private func startTutorial(in root: Entity) async {
        print("\n=== Starting Tutorial Sequence ===")
        
        if let gameStartVO = await appModel.assetLoadingManager.instantiateEntity("game_start_vo") {
            if let VO_parent = root.findEntity(named: "Decoy") {
                print("🎯 Found tutorial VO parent")
                VO_parent.addChild(gameStartVO)
                root.addChild(VO_parent)
                
                // Find tutorial cancer cell using existing pattern
                if let cell = gameStartVO.findEntity(named: "CancerCell_spawn") {
                    print("✅ Found tutorial cancer cell")
                    tutorialCancerCell = cell
                    
                    // Set up tutorial cell using ViewModel
                    appModel.gameState.setupTutorialCancerCell(cell)
                    
                    // Start ADC firing sequence
                    Task {
                        await fireTutorialADCs()
                    }
                } else {
                    print("❌ Could not find tutorial cancer cell")
                }
            }
        }
    }
    
    @MainActor
    private func fireTutorialADCs() async {
        print("\n=== Starting Tutorial ADC Sequence ===")
        let launchPosition = SIMD3<Float>(0.25, 0.5, -0.25)
        
        for (_, delay) in tutorialADCDelays.enumerated() {
            try? await Task.sleep(for: .seconds(delay))
//            print("🚀 Firing tutorial ADC \(index + 1)/10")
            await appModel.gameState.handleTap(
                on: tutorialCancerCell!,
                location: launchPosition,
                in: scene
            )
        }
//        print("✅ Tutorial ADC sequence complete")
        
        // Wait until 24s mark
//        print("⏱️ Waiting for 24s mark...")
        try? await Task.sleep(for: .seconds(5))  // 19s + 5s = 24s
        
//        print("🎯 Opening hope meter utility window")
        if !appModel.isHopeMeterUtilityWindowOpen {
            openWindow(id: AppModel.hopeMeterUtilityWindowId)
            appModel.isHopeMeterUtilityWindowOpen = true
        }
        
//        print("🎮 Setting up cancer cells")
        if let root = appModel.gameState.rootEntity, let attachments = appModel.gameState.storedAttachments {
            await setupGameContent(in: root, attachments: attachments)
        }
    }
    
    @MainActor
    private func setupUIAttachments(in root: Entity, attachments: RealityViewAttachments, count: Int) {
        print("\n=== Setting up UI Attachments ===")
        print("Total attachments to create: \(count)")
        
        for i in 0..<count {
            print("Setting up attachment \(i)")
            if let meter = attachments.entity(for: "\(i)") {
                print("✅ Found meter entity for \(i)")
                if root.findEntity(named: "cancer_cell_\(i)") != nil {
                    print("✅ Found cancer cell \(i)")
                    root.addChild(meter)
                    meter.components[UIAttachmentComponent.self] = UIAttachmentComponent(attachmentID: i)
                    meter.components.set(BillboardComponent())
//                    meter.scale *= 0.4
//                    meter.position.y += 0.3
                    
                    print("✅ Added meter to cancer_cell_\(i) with components")
                } else {
                    print("❌ Could not find cancer cell \(i)")
                }
            } else {
                print("❌ Could not create meter entity for \(i)")
            }
        }
    }
    
    private func makeTapGesture() -> some Gesture {
        SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                // Check if this is first tap and hope meter hasn't started
//                 if appModel.gameState.totalTaps == 0 && !appModel.gameState.isHopeMeterRunning {
//                     // check this window dismissal
// //                    dismissWindow(id: AppModel.mainWindowId)
// //                    appModel.isMainWindowOpen = false
                    
//                     appModel.startAttackCancerGame()
// //                    openWindow(id: AppModel.mainWindowId)
//                     if !appModel.isHopeMeterUtilityWindowOpen {
//                         openWindow(id: AppModel.hopeMeterUtilityWindowId)
//                         appModel.isHopeMeterUtilityWindowOpen = true
//                     }
//                 }
                
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
    }
}
