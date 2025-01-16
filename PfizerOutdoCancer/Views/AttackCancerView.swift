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
    
    // Add simulator check
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    var body: some View {
        RealityView { content, attachments in
            let root = appModel.gameState.setupRoot()
            root.name = "AttackCancerRoot"
            
            // Add PositioningComponent to keep world tracking active
            root.components.set(PositioningComponent(
                offsetX: 0,
                offsetY: 0,
                offsetZ: 0
            ))
            
            content.add(root)
            
            if !isSimulator {
                setupHandTracking(in: content, attachments: attachments)
            }
            
            Task {
                await setupGameContent(in: root, attachments: attachments)
            }
        } attachments: {
            // HopeMeter attachment
            Attachment(id: "HopeMeter") {
                HopeMeterView()
            }
            
            // Cell counter attachments
            ForEach(0..<appModel.gameState.maxCancerCells, id: \.self) { i in
                Attachment(id: "\(i)") {
                    if i < cellStates.count {
                        HitCounterView(
                            hits: cellStates[i].hits,
                            requiredHits: cellStates[i].requiredHits,
                            isDestroyed: cellStates[i].isDestroyed
                        )
                    } else {
                        HitCounterView(hits: 0, requiredHits: 0, isDestroyed: false)
                    }
                }
            }
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
        .task {
            await appModel.monitorSessionEvents()
        }
        .task {
            try? await appModel.runARKitSession()
        }
    }
    
    // 4. Hand tracking setup method
    private func setupHandTracking(in content: RealityViewContent, attachments: RealityViewAttachments) {
        let handAnchor = AnchorEntity(.hand(.left, location: .aboveHand))
        handTrackedEntity = handAnchor
        content.add(handAnchor)
        
        content.add(appModel.handTracking.setupContentEntity())
        
        if let attachmentEntity = attachments.entity(for: "HopeMeter") {
            attachmentEntity.components[BillboardComponent.self] = BillboardComponent()
            attachmentEntity.scale *= 0.6
            attachmentEntity.position.z -= 0.02
            handAnchor.addChild(attachmentEntity)
        }
    }
    
    @MainActor
    private func setupGameContent(in root: Entity, attachments: RealityViewAttachments) async {
        print("\n=== Initializing Cell States ===")
        cellStates = Array(repeating: CellState(), count: appModel.gameState.maxCancerCells)
        
        await appModel.gameState.setupEnvironment(in: root)
        
        // ADC template is already set up during phase transition
        
        if let cancerCellTemplate = await appModel.assetLoadingManager.instantiateEntity("cancer_cell") {
            let maxCells = appModel.gameState.maxCancerCells
            appModel.gameState.spawnCancerCells(in: root, from: cancerCellTemplate, count: maxCells)
            setupUIAttachments(in: root, attachments: attachments, count: maxCells)
            
            // Update required hits and setup hit tracking
            for i in 0..<maxCells {
                if let cell = root.findEntity(named: "cancer_cell_\(i)")?.findEntity(named: "cancerCell_complex") {
                    // Set initial required hits
                    if let state = cell.components[CancerCellStateComponent.self] {
                        cellStates[i].requiredHits = state.parameters.requiredHits
                        print("🎯 Counter \(i) ready: \(cellStates[i].hits)/\(cellStates[i].requiredHits)")
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
                                    print("💀 Cell \(i) destroyed - Total destroyed: \(appModel.gameState.cellsDestroyed)")
                                }
                                
                                // Only log actual changes
                                if oldHits != state.parameters.hitCount {
                                    print("📊 Cell \(i): \(state.parameters.hitCount)/\(state.parameters.requiredHits) hits")
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
                if appModel.gameState.totalTaps == 0 && !appModel.gameState.isHopeMeterRunning {
                    dismissWindow(id: AppModel.mainWindowId)
                    appModel.isMainWindowOpen = false
                    appModel.startHopeMeter()
                }
                
                // Existing tap handling code
                let location3D = value.convert(value.location3D, from: .local, to: .scene)
                appModel.gameState.totalTaps += 1
                print("\n👆 TAP #\(appModel.gameState.totalTaps) on \(value.entity.name)")
                
                Task {
                    await appModel.gameState.handleTap(on: value.entity, location: location3D, in: scene)
                }
            }
    }
}
