import SwiftUI
import RealityKit
import RealityKitContent

extension AttackCancerViewModel {
    // MARK: - Setup Functions
    func setupRoot() -> Entity {
        print("📱 AttackCancerViewModel: Setting up root")
        let root = Entity()
        root.name = "AttackCancerRoot"
        
        // Keep headTrackingRoot setup - needed for AttackCancer functionality
        let headTrackingRoot = Entity()
        headTrackingRoot.name = "headTrackingRoot"
        headTrackingRoot.components.set(PositioningComponent(
            offsetX: 0,
            offsetY: 0,
            offsetZ: -1.0
        ))
        root.addChild(headTrackingRoot)
        
        rootEntity = root
        return root
    }
    
    func setupEnvironment(in root: Entity, attachments: RealityViewAttachments) async {
        print("🎯 Setting up AttackCancerView environment...")
        
        // IBL
        do {
            try await IBLUtility.addImageBasedLighting(to: root, imageName: "metro_noord_2k")
        } catch {
            print("Failed to setup IBL: \(error)")
            return
        }
        
        // Environment
        do {
            let attackCancerScene = try await appModel.assetLoadingManager.instantiateAsset(
                withName: "attack_cancer_environment",
                category: .attackCancerEnvironment
            )
            root.addChild(attackCancerScene)
            print("setting up collisions")
            setupCollisions(in: attackCancerScene)
            
            print("✅ Environment setup complete")
            environmentLoaded = true
        } catch {
            print("❌ Failed to load attack cancer environment: \(error)")
            environmentLoaded = false
        }
        
        // Setup game content with attachments
//        await setupGameContent(in: root, attachments: attachments)
    }
    
    func setupIBL(in root: Entity) async {
        do {
            try await IBLUtility.addImageBasedLighting(to: root, imageName: "metro_noord_2k")
        } catch {
            print("Failed to setup IBL: \(error)")
        }
    }
    
    func startTutorial(in root: Entity, attachments: RealityViewAttachments) async {
        print("\n=== Starting Tutorial Sequence ===")
        
        // Ensure we have the scene reference
        scene = root.scene
        
        do {
            print("📱 Tutorial: Loading game start VO")
            let gameStartVO = try await appModel.assetLoadingManager.instantiateAsset(
                withName: "game_start_vo",
                category: .attackCancerEnvironment
            )
            print("✅ Tutorial: Retrieved game start VO")
            
            if let VO_parent = root.findEntity(named: "headTrackingRoot") {
                print("🎯 Tutorial: Found VO parent")
                VO_parent.addChild(gameStartVO)
                root.addChild(VO_parent)
                print("✅ Tutorial: Added VO to scene")
                
                // Find tutorial cancer cell using existing pattern
                if let cell = gameStartVO.findEntity(named: "CancerCell_spawn") {
                    print("✅ Tutorial: Found tutorial cancer cell")
                    tutorialCancerCell = cell
                    
                    // Set up tutorial cell using ViewModel
                    setupTutorialCancerCell(cell)
                    print("✅ Tutorial: Cancer cell setup complete")
                    
                    // Start ADC firing sequence
                    Task {
                        await fireTutorialADCs(in: root, attachments: attachments)
                    }
                    print("✅ Tutorial: ADC sequence initiated")
                    isSetupComplete = true
                } else {
                    print("❌ Tutorial: Could not find CancerCell_spawn")
                }
            } else {
                print("❌ Tutorial: Could not find headTrackingRoot entity")
            }
        } catch {
            print("❌ Tutorial: Failed to load game start VO: \(error)")
        }
    }
    
    private func fireTutorialADCs(in root: Entity, attachments: RealityViewAttachments) async {
        print("\n=== Starting Tutorial ADC Sequence ===")
        
        // Launch position is slightly offset to the right and above
        let launchPosition = SIMD3<Float>(0.25, 0.5, -0.25)
        
        // Calculate approach vector that points towards the cell from slightly in front
        // This ensures ADCs prefer antigens facing the player's view
        let approachPosition = SIMD3<Float>(0, 0.5, -1.0)  // Position in front of the cell

        // Find the cancerCell_complex within the tutorial cell
        guard let complexCell = tutorialCancerCell?.findEntity(named: "cancerCell_complex") else {
            print("❌ Could not find cancerCell_complex in tutorial cell")
            return
        }
        
        for (index, delay) in tutorialADCDelays.enumerated() {
            try? await Task.sleep(for: .seconds(delay))
            print("🚀 Firing tutorial ADC \(index + 1)/10")
            await handleTap(
                on: complexCell,
                location: approachPosition,  // Use approach position for targeting
                in: scene
            )
        }
        print("✅ Tutorial ADC sequence complete")
        
        // Wait until 24s mark
        print("⏱️ Waiting for 24s mark...")
        try? await Task.sleep(for: .seconds(2))  // 19s + 5s = 24s
        
        print("🎯 Opening hope meter utility window")
        if !appModel.isHopeMeterUtilityWindowOpen {
            appModel.isHopeMeterUtilityWindowOpen = true
        }
        
        print("🎮 Setting up cancer cells")
        await setupGameContent(in: root, attachments: attachments)
    }
    
    func handleGameStart(in root: Entity) async {
        // Fade out tutorial
        if let tutorialContent = root.findEntity(named: "headTrackingRoot") {
            await tutorialContent.fadeOpacity(to: 0, duration: 1)
        }
    }

    @MainActor
    private func setupGameContent(in root: Entity, attachments: RealityViewAttachments) async {
        print("\n=== Initializing Cell States ===")
        cellStates = Array(repeating: CellState(), count: maxCancerCells)
        
        // ADC template is already set up during phase transition
        
        do {
            let cancerCellTemplate = try await appModel.assetLoadingManager.instantiateAsset(
                withName: "cancer_cell",
                category: .cancerCell
            )
            let maxCells = maxCancerCells
            await spawnCancerCells(in: root, from: cancerCellTemplate, count: maxCells)
//            setupUIAttachments(in: root, attachments: attachments, count: maxCells)
            
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
        } catch {
            print("❌ Failed to load cancer cell template: \(error)")
        }
    }
    
}
