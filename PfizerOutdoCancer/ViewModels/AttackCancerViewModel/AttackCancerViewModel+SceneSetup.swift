import SwiftUI
import RealityKit
import RealityKitContent

extension AttackCancerViewModel {
    // MARK: - Setup Functions
    func setupRoot() -> Entity {
        // Reset the cleanup state for a new game session.
        cleanupState = .none
        
        // Reset state tracking
        isRootSetupComplete = false
        isEnvironmentSetupComplete = false
        isHeadTrackingRootReady = false
        isPositioningComplete = false
        
        Logger.info("🔄 Starting new game session: cleanupState and tracking states reset")
        Logger.info("📱 AttackCancerViewModel: Setting up root")
        
        let root = Entity()
        root.name = "AttackCancerRoot"
        // root.enableLargeRoomReverb()
        // root.position = AppModel.PositioningDefaults.playing.position
        
        // Keep headTrackingRoot setup - needed for AttackCancer functionality
        let headTrackingRoot = Entity()
        headTrackingRoot.position = AppModel.PositioningDefaults.playing.position
        headTrackingRoot.name = "headTrackingRoot"
        headTrackingRoot.components.set(PositioningComponent(
            offsetX: 0,
            offsetY: 0,
            offsetZ: -1.0,
            needsPositioning: false,
            shouldAnimate: false,
            animationDuration: 0.0
        ))
        root.addChild(headTrackingRoot)
        
        Logger.info("""
        
        ✅ Root Setup Complete
        ├─ Root Entity: \(root.name)
        ├─ HeadTracking Root: Added
        ├─ Position: \(headTrackingRoot.position(relativeTo: nil))
        └─ Positioning: Ready for explicit updates
        """)
        
        rootEntity = root
        isRootSetupComplete = true
        isHeadTrackingRootReady = true
        return root
    }
    
    func setupEnvironment(in root: Entity, attachments: RealityViewAttachments? = nil) async {
        Logger.info("\n🎯 Setting up AttackCancerView environment...")
        
        // prepare audio
        await prepareEndGameAudio()
        
        // IBL
        do {
            try await IBLUtility.addImageBasedLighting(to: root, imageName: "metro_noord_2k", intensity: 0.5)
        } catch {
            Logger.error("Failed to setup IBL: \(error)")
            isEnvironmentSetupComplete = false
            return
        }
        
        // Environment
        do {
            let environment = try await appModel.assetLoadingManager.instantiateAsset(
                withName: "attack_cancer_environment",
                category: .attackCancerEnvironment
            )
            
            root.addChild(environment)
            
            Logger.info("setting up collisions")
            setupCollisions(in: environment)
            
            // Set up the scene
            scene = root.scene
            
            // Initialize cancer cell pool early
            do {
                Logger.info("🎯 Pre-initializing cancer cell pool...")
                let cancerCellTemplate = try await appModel.assetLoadingManager.instantiateAsset(
                    withName: "cancer_cell",
                    category: .cancerCell
                )
                
                let createdCount = await initializePool(in: root, template: cancerCellTemplate)
                Logger.info("✅ Pool pre-initialized with \(createdCount) cells")
            } catch {
                Logger.error("❌ Failed to pre-initialize cancer cell pool: \(error)")
            }

            // prepare audio
            await prepareEndGameAudio()
            
            Logger.info("""
            
            ✅ Environment Setup Complete
            ├─ IBL: Configured
            ├─ Environment: Loaded
            ├─ Collisions: Setup
            ├─ Cell Pool: Pre-initialized
            └─ End Game Audio: Loaded
            """)
            
            environmentLoaded = true
            isEnvironmentSetupComplete = true
        } catch {
            Logger.error("❌ Error setting up AttackCancerView environment: \(error)")
            environmentLoaded = false
            isEnvironmentSetupComplete = false
        }
        
        // NEW: Retrieve the shared CancerCellSystem (set via automatic registration)
        if let cancerSystem = CancerCellSystem.shared {
            self.cancerCellSystem = cancerSystem
            // Assign the onCellDestroyed closure.
            cancerSystem.onCellDestroyed = { [weak self] cellID in
                guard let self = self else { return }
                self.cellsDestroyed += 1
                Logger.info("Incremented cellsDestroyed to \(self.cellsDestroyed)")
                
                // Check if this was the test fire cell (ID 555)
                if cellID == 555 {
                    Logger.info("\nTest fire cell (ID 555) was destroyed")
                    testFireComplete = true
                    Logger.info(">>> Test fire complete - opening hope meter window...\n")

                    readyToStartGame = true
                    Logger.info(">>> Setting readyToStartGame to true...\n")

                    isTestFireActive = false
                    Logger.info(">>> Setting isTestFireActive to false...\n")
                } else {
                    // For other cells, check game conditions
                    self.checkGameConditions()
                }
            }
        }
    }
    
    // convenience function for Instructions screen
    func setupIBL(in root: Entity) async {
        do {
            try await IBLUtility.addImageBasedLighting(to: root, imageName: "metro_noord_2k", intensity: 0.5)
        } catch {
            Logger.error("Failed to setup IBL: \(error)")
        }
    }
    
    func startTutorial(in root: Entity, attachments: RealityViewAttachments? = nil) async {
        Logger.info("\n=== Starting Tutorial Sequence ===")
        
        // Ensure we have the scene reference
        scene = root.scene
        
        do {
            Logger.info("📱 Tutorial: Loading game start VO")
            let gameStartVO = try await appModel.assetLoadingManager.instantiateAsset(
                withName: "game_start_vo",
                category: .attackCancerEnvironment
            )
            Logger.info("✅ Tutorial: Retrieved game start VO")
            
            if let VO_parent = root.findEntity(named: "headTrackingRoot") {
                Logger.info("🎯 Tutorial: Found VO parent")
                VO_parent.addChild(gameStartVO)
                print("gameStartVO world position = \(gameStartVO.position(relativeTo: nil))")
                root.addChild(VO_parent)
                Logger.info("✅ Tutorial: Added VO to scene")
                
                // Add the tutorial alert to the VO parent if it exists
                if let tutorialAlert = attachments?.entity(for: "TutorialAlert") {
                    Logger.info("🎯 Tutorial: Positioning tutorial alert")
                    
                    // Position it in front of the cancer cell, slightly above
                    tutorialAlert.position = SIMD3<Float>(0, -0.25, 0.25)
                    
                    // Add it to the VO parent
                    VO_parent.addChild(tutorialAlert)
                    
                    Logger.info("✅ Tutorial: Added tutorial alert to scene")
                }
                
                // Position the pinch animation entity if it exists
                if let pinchAnimation = attachments?.entity(for: "PinchAnimation") {
                    Logger.info("🎯 Tutorial: Positioning pinch animation")
                    
                    // Position it exactly like the tutorial alert
                    pinchAnimation.position = SIMD3<Float>(0, -0.25, 0.25)
                    
                    // Add it to the VO parent but keep it hidden initially
                    VO_parent.addChild(pinchAnimation)
                    isPinchAnimationVisible = false // Will be set to true when test fire cell is spawned
                    
                    Logger.info("✅ Tutorial: Added pinch animation to scene (initially hidden)")
                }
                
                // Find tutorial cancer cell using existing pattern
                if let cell = gameStartVO.findEntity(named: "CancerCell_spawn") {
                    Logger.info("✅ Tutorial: Found tutorial cancer cell")
                    tutorialCancerCell = cell
                    
                    // Set up tutorial cell using ViewModel
                    setupTutorialCancerCell(cell)
                    Logger.info("✅ Tutorial: Cancer cell setup complete")
                    
                    // Start ADC firing sequence
                    Task {
                        await fireTutorialADCs(in: root)
                    }
                    Logger.info("✅ Tutorial: ADC sequence initiated")
                    isSetupComplete = true
                } else {
                    Logger.error("❌ Tutorial: Could not find CancerCell_spawn")
                }
            } else {
                Logger.error("❌ Tutorial: Could not find headTrackingRoot entity")
            }
        } catch {
            Logger.error("❌ Tutorial: Failed to load game start VO: \(error)")
        }
    }
    
    internal func playStartButtonVO(in root: Entity) async {
        Logger.info("\n=== Playing Start Button VO ===")
        do {
            let startButtonVO = try await appModel.assetLoadingManager.instantiateAsset(
                withName: "PressStart_VO",
                category: .attackCancerEnvironment
            )
            Logger.info("✅ Retrieved start button VO")
            
            if let VO_parent = root.findEntity(named: "headTrackingRoot") {
                Logger.info("🎯 Found VO parent")
                VO_parent.addChild(startButtonVO)
                Logger.info("✅ Added start button VO to scene")
            } else {
                Logger.error("❌ Could not find headTrackingRoot entity")
            }
        } catch {
            Logger.error("❌ Failed to load start button VO: \(error)")
        }
    }
    
    private func fireTutorialADCs(in root: Entity, attachments: RealityViewAttachments? = nil) async {
        Logger.info("\n=== Starting Tutorial ADC Sequence ===")
        
        // Show the tutorial alert before starting
        isTutorialAlertVisible = true
        Logger.info("✅ Tutorial alert visible")
        
        // Launch position is slightly offset to the right and above
        _ = SIMD3<Float>(0.25, 0.5, -0.25)
        
        // Calculate approach vector that points towards the cell from slightly in front
        // This ensures ADCs prefer antigens facing the player's view
        let approachPosition = SIMD3<Float>(0, 0.5, -1.0)  // Position in front of the cell

        // Find the cancerCell_complex within the tutorial cell
        guard let complexCell = tutorialCancerCell?.findEntity(named: "cancerCell_complex") else {
            Logger.error("❌ Could not find cancerCell_complex in tutorial cell")
            return
        }
        
        // Fire the first 8 ADCs with the alert visible
        for (index, delay) in tutorialADCDelays.prefix(6).enumerated() {
            try? await Task.sleep(for: .seconds(delay))
            Logger.info("🚀 Firing tutorial ADC \(index + 1)/10")
            await handleTap(
                on: complexCell,
                location: approachPosition,  // Use approach position for targeting
                in: scene
            )
        }
        
        // Hide the tutorial alert when there are 2 shots left
        isTutorialAlertVisible = false
        Logger.info("✅ Tutorial alert hidden after 6 shots")
        
        // Fire the remaining 2 ADCs
        for (index, delay) in tutorialADCDelays.suffix(4).enumerated() {
            try? await Task.sleep(for: .seconds(delay))
            Logger.info("🚀 Firing tutorial ADC \(index + 9)/10")
            await handleTap(
                on: complexCell,
                location: approachPosition,  // Use approach position for targeting
                in: scene
            )
        }
        
        Logger.info("✅ Tutorial ADC sequence complete")
        
        Logger.info("⏱️ small delay before the test fire cell is spawned")
        try? await Task.sleep(for: .seconds(2.2))  
        
        // Check current state before spawning test fire cell
        Logger.info("🔍 PINCH DEBUG (Before Test Fire): hasFirstADCBeenFired: \(hasFirstADCBeenFired), isPinchAnimationVisible: \(isPinchAnimationVisible), totalADCsDeployed: \(totalADCsDeployed)")
        
        // Reset the hasFirstADCBeenFired flag since tutorial ADCs shouldn't count for hiding the pinch animation
        hasFirstADCBeenFired = false
        Logger.info("🔍 PINCH DEBUG (Test Fire Reset): Set hasFirstADCBeenFired = false to ensure pinch animation works properly")
        
        // MARK: SPAWN TEST FIRE CELL
        Logger.info("\n🎯 Starting test fire sequence...\n")
        Task { @MainActor in
            await spawnTestFireCell(in: root)
        }

        // add a small delay to set readyToStartGame to true
        try? await Task.sleep(for: .seconds(8))
        
        appModel.gameState.tutorialComplete = true
        Logger.info("✅ Set tutorial complete to true")
        
        // set tutorial complete as a check so that the press start audio doesn't start too soon
        
        // set readyToStartGame to true in closure that checks for test fire completion
        
        // Test fire sequence active – deferring full game cell spawning until test fire is completed.
        // The full game setup will be triggered later (e.g., via UI when the start game button is pressed).
    }
    
    func handleGameStart(in root: Entity) async {
        // Fade out tutorial
        if let tutorialContent = root.findEntity(named: "headTrackingRoot") {
            await tutorialContent.fadeOpacity(to: 0, duration: 1)
        }
    }

    @MainActor
    func setupGameContent(in root: Entity, attachments: RealityViewAttachments? = nil) async {
        Logger.info("\n=== Initializing Game Content ===")
        
        // Reset game state before starting main game
        appModel.gameState.cellsDestroyed = 0
        // cellParameters.removeAll()
        
        // Reset pool to ensure clean state
        // Logger.info("Resetting cell pool to clean state...")
        // resetPool()
        
        // Use pooled spawning
        await spawnCancerCellsFromPool()
        
        // Verify and initialize each cell's state
        for i in 0..<maxCancerCells {
            if let cell = root.findEntity(named: "cancer_cell_\(i)")?.findEntity(named: "cancerCell_complex") {
                if let stateComponent = cell.components[CancerCellStateComponent.self] {
                    Logger.info("🎯 Cell \(i) initialized - Required hits: \(stateComponent.parameters.requiredHits)")
                }
            }
        }
        
        Logger.info("Cell Parameters after setup:")
        for (index, params) in cellParameters.enumerated() {
            Logger.info("  Cell \(index): isTutorialCell=\(params.isTutorialCell), isDestroyed=\(params.isDestroyed)")
        }
    }

    @MainActor
    func setupGameContentOriginal(in root: Entity, attachments: RealityViewAttachments? = nil) async {
        Logger.info("\n=== Initializing Cell States ===")
        
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
            
            // Update required hits and setup hit tracking
            for i in 0..<maxCells {
                if let cell = root.findEntity(named: "cancer_cell_\(i)")?.findEntity(named: "cancerCell_complex") {
                    // Set initial required hits
                    if let stateComponent = cell.components[CancerCellStateComponent.self] {
                        Logger.info("🎯 Cell \(i) initialized - Required hits: \(stateComponent.parameters.requiredHits)")
                    }
                }
            }

            Logger.info("Cell Parameters after setup:")
            for (index, params) in cellParameters.enumerated() {
                Logger.info("  Cell \(index): isTutorialCell=\(params.isTutorialCell), isDestroyed=\(params.isDestroyed)")
            }

        } catch {
            Logger.error("❌ Failed to load cancer cell template: \(error)")
        }
    }
}
