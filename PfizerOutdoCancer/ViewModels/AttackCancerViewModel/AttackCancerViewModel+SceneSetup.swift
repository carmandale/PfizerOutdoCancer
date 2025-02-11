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
    
    func setupEnvironment(in root: Entity, attachments: RealityViewAttachments? = nil) async {
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
            let environment = try await appModel.assetLoadingManager.instantiateAsset(
                withName: "attack_cancer_environment",
                category: .attackCancerEnvironment
            )

            root.addChild(environment)

            print("setting up collisions")
            setupCollisions(in: environment)
            
            print("✅ Environment setup complete")
            environmentLoaded = true
        } catch {
            print("❌ Error setting up AttackCancerView environment: \(error)")
            environmentLoaded = false
        }
    }
    
    func setupIBL(in root: Entity) async {
        do {
            try await IBLUtility.addImageBasedLighting(to: root, imageName: "metro_noord_2k")
        } catch {
            print("Failed to setup IBL: \(error)")
        }

        // NEW: Find the CancerCellSystem in the scene and assign its callback.
        if let cancerSystem = root.scene?.systems.first(where: { $0 is CancerCellSystem }) as? CancerCellSystem {
            cancerSystem.onCellDestroyed = { [weak self] in
                guard let self = self else { return }
                self.cellsDestroyed += 1
                print("Incremented cellsDestroyed to \(self.cellsDestroyed)")
                self.checkGameConditions()
            }
        }
    }
    
    func startTutorial(in root: Entity, attachments: RealityViewAttachments? = nil) async {
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
                        await fireTutorialADCs(in: root)
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
    
    private func fireTutorialADCs(in root: Entity, attachments: RealityViewAttachments? = nil) async {
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
        await setupGameContent(in: root)
    }
    
    func handleGameStart(in root: Entity) async {
        // Fade out tutorial
        if let tutorialContent = root.findEntity(named: "headTrackingRoot") {
            await tutorialContent.fadeOpacity(to: 0, duration: 1)
        }
    }

    @MainActor
    private func setupGameContent(in root: Entity, attachments: RealityViewAttachments? = nil) async {
        print("\n=== Initializing Cell States ===")
        
        // Reset game state before starting main game
        appModel.gameState.cellsDestroyed = 0
        cellParameters.removeAll()
        
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
                    if let stateComponent = cell.components[CancerCellStateComponent.self] {
                        print("🎯 Cell \(i) initialized - Required hits: \(stateComponent.parameters.requiredHits)")
                    }
                }
            }

            print("Cell Parameters after setup:") // ADDED LOG
            for (index, params) in cellParameters.enumerated() {
                print("  Cell \(index): isTutorialCell=\(params.isTutorialCell), isDestroyed=\(params.isDestroyed)") // ADDED LOG
            }
            
            // print("🎮 Game Content Setup Complete - Starting Hope Meter")
            // appModel.startHopeMeter()
        } catch {
            print("❌ Failed to load cancer cell template: \(error)")
        }
    }
    
}
