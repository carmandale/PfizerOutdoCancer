import SwiftUI
import RealityKitContent
import RealityKit

extension AttackCancerViewModel {
    // MARK: - Notification Setup (This is now just for the timeline)
    func handleTimelineNotification(for entity: Entity) {
        // Add debug logging
        print("📢 Timeline notification received from \(entity.name)")
        
        // Main thread execution for UI updates
        DispatchQueue.main.async {
            print("🎯 Opening hope meter utility window")
            if !self.appModel.isHopeMeterUtilityWindowOpen {
                self.appModel.isHopeMeterUtilityWindowOpen = true
            }
        }
    }

    // No longer needed: setupNotifications, handleCancerCellUpdate, notifyCellStateChanged, notifyGameStateChanged, notifyScoreChanged

    func checkGameConditions() {
        // Only check game completion if the game is actually active
        guard isGameActive else {
            #if DEBUG
            print("\n⚠️ Game State Check (NOT ACTIVE):")
            print("  - Tutorial Complete: \(tutorialComplete)")
            print("  - Hope Meter Running: \(isHopeMeterRunning)")
            print("  - Game Active: false\n")
            #endif
            return
        }
        
        #if DEBUG
        print("\n🎮 Game State Active:")
        print("  - Tutorial Complete: \(tutorialComplete)")
        print("  - Hope Meter Running: \(isHopeMeterRunning)")
        print("  - Game Active: true")
        #endif
        
        // Check if all *game* cells are destroyed (exclude tutorial cell)
        let gameCells = cellParameters.filter { !$0.isTutorialCell }
        let destroyedGameCells = gameCells.filter { $0.isDestroyed }.count

        #if DEBUG
        print("\n=== Game Completion Check ===")
        print("📊 Game Cells Status:")
        for (index, cell) in gameCells.enumerated() {
            print("  Game Cell \(index):")
            print("    - Is Destroyed: \(cell.isDestroyed)")
            print("    - Hit Count: \(cell.hitCount)/\(cell.requiredHits)")
        }
        print("\n📈 Summary:")
        print("  - Total game cells: \(gameCells.count)")
        print("  - Destroyed game cells: \(destroyedGameCells)")
        print("  - All cells destroyed: \(destroyedGameCells >= gameCells.count)")
        print("=== End Completion Check ===\n")
        #endif

        if destroyedGameCells >= gameCells.count {
            print("✅✅✅ ALL GAME CELLS DESTROYED! Condition met!")
            Task { @MainActor in
                print("🎯 All game cells destroyed - accelerating hope meter")
                await appModel.accelerateHopeMeterToCompletion()
            }
        }
    }
}
