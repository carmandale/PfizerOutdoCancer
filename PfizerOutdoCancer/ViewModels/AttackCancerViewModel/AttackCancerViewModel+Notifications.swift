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
        // Instead, use the global cellsDestroyed counter updated by the CancerCellSystem.
        let totalGameCells = cellParameters.filter { !$0.isTutorialCell }.count
        #if DEBUG
        print("\n=== Game Completion Check ===")
        print("  - Total game cells: \(totalGameCells)")
        print("  - Global destroyed cells: \(cellsDestroyed)")
        #endif
        
        if totalGameCells > 0, cellsDestroyed >= totalGameCells {
            print("✅✅✅ ALL GAME CELLS DESTROYED! Condition met!")
            Task { @MainActor in
                print("🎯 All game cells destroyed - accelerating hope meter")
                await appModel.accelerateHopeMeterToCompletion()
                // Wait for an additional 2 seconds after accelerateHopeMeterToCompletion finishes.
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await appModel.transitionToPhase(.completed)
            }
        }
    }
}
