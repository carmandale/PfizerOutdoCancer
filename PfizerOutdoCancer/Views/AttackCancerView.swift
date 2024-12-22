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
    @Environment(\.realityKitScene) private var scene
    @State private var cellStates: [CellState] = []
    
    // 1. Hand tracking entity setup
    @State private var handTrackedEntity: Entity = {
        let handAnchor = AnchorEntity(.hand(.left, location: .aboveHand))
        return handAnchor
    }()
    
    var body: some View {
        RealityView { content, attachments in
            let root = appModel.gameState.setupRoot()
            content.add(root)
            
            // 2. Call setupHandTracking
            setupHandTracking(in: content, attachments: attachments)
            
            Task {
                await setupGameContent(in: root, attachments: attachments)
                
                print("\n=== Initializing Cell States ===")
                // Initialize with actual required hits from state components
                cellStates = Array(repeating: CellState(), count: appModel.gameState.maxCancerCells)
                
                // Update required hits from existing cell states
                for i in 0..<appModel.gameState.maxCancerCells {
                    if let cell = root.findEntity(named: "cancer_cell_\(i)")?.findEntity(named: "cancerCell_complex"),
                       let state = cell.components[CancerCellStateComponent.self] {
                        cellStates[i].requiredHits = state.parameters.requiredHits
                    }
                }
                
                print("✅ Created \(cellStates.count) cell states")
                
                // Log initial states with correct required hits
                for i in 0..<cellStates.count {
                    print("🎯 Counter \(i) ready: 0/\(cellStates[i].requiredHits)")
                }
                
                // Setup hit tracking
                for i in 0..<appModel.gameState.maxCancerCells {
                    if let cell = root.findEntity(named: "cancer_cell_\(i)")?.findEntity(named: "cancerCell_complex") {
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
            }
        } attachments: {
            // 3. HopeMeter attachment
            Attachment(id: "HopeMeter") {
                HopeMeterView()
            }
            
            // Keep existing cell counter attachments
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
        .onAppear { appModel.gameState.startGame() }
    }
    
    // 4. Hand tracking setup method
    private func setupHandTracking(in content: RealityViewContent, attachments: RealityViewAttachments) {
        content.add(appModel.handTracking.setupContentEntity())
        content.add(handTrackedEntity)
        if let attachmentEntity = attachments.entity(for: "HopeMeter") {
            attachmentEntity.components[BillboardComponent.self] = BillboardComponent()
            handTrackedEntity.addChild(attachmentEntity)
        }
    }
    
    @MainActor
    private func setupGameContent(in root: Entity, attachments: RealityViewAttachments) async {
        await appModel.gameState.setupEnvironment(in: root)
        
        if let adcEntity = await appModel.assetLoadingManager.instantiateEntity("adc") {
            appModel.gameState.setADCTemplate(adcEntity)
        }
        
        if let cancerCellTemplate = await appModel.assetLoadingManager.instantiateEntity("cancer_cell") {
            let maxCells = appModel.gameState.maxCancerCells
            appModel.gameState.spawnCancerCells(in: root, from: cancerCellTemplate, count: maxCells)
            setupUIAttachments(in: root, attachments: attachments, count: maxCells)
        }
    }
    
    private func setupUIAttachments(in root: Entity, attachments: RealityViewAttachments, count: Int) {
        print("\n=== Setting up UI Attachments ===")
        print("Total attachments to create: \(count)")
        
        for i in 0..<count {
            print("Setting up attachment \(i)")
            if let meter = attachments.entity(for: "\(i)") {
                print("✅ Found meter entity for \(i)")
                if let cell = root.findEntity(named: "cancer_cell_\(i)") {
                    print("✅ Found cancer cell \(i)")
                    root.addChild(meter)
                    meter.components[UIAttachmentComponent.self] = UIAttachmentComponent(attachmentID: i)
                    meter.components.set(BillboardComponent())
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
                let location3D = value.convert(value.location3D, from: .local, to: .scene)
                appModel.gameState.totalTaps += 1
                print("\n👆 TAP #\(appModel.gameState.totalTaps) on \(value.entity.name)")
                
                Task {
                    await appModel.gameState.handleTap(on: value.entity, location: location3D, in: scene)
                }
            }
    }
}
