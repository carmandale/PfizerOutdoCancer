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
                // Play the end game tone using our new function
                await self.playEndSound("magic_zing", forSequence: .victory) // Added forSequence parameter
                
                // Delay a second to give the user a moment to look forward
                try? await Task.sleep(for: .milliseconds(1000))
                print("🎯 All game cells destroyed - accelerating hope meter")
                await appModel.accelerateHopeMeterToCompletion()
                // Wait for an additional 2 seconds after accelerateHopeMeterToCompletion finishes.
                try? await Task.sleep(for: .milliseconds(2000))
                await appModel.transitionToPhase(.completed)
            }
        }
    }

    // Optionally, if there's an area where the hope meter runs out, add a call there as well:
    func hopeMeterDidRunOut() async {
        Task { @MainActor in
            // Play the end game tone when hope meter runs out
            Logger.audio("\n=== playing end sound ===\n")
            await self.playVictorySequence() // self.playEndSound("heartbeat") // Example of playing a different sound
            // Additional actions can be added here
        }
    }
    
    /// Monitor hope meter time and trigger events at specific thresholds
    func checkHopeMeterThresholds() {
        // Only check if the game is active
        guard isGameActive else { return }
        
        // Check for 19 seconds remaining
        if hopeMeterTimeLeft <= 19 && hopeMeterTimeLeft > 18 {
            Logger.audio("Hope meter at 19 seconds - triggering ending sequence")
            Task { @MainActor in
                await playEndingSequence()
            }
        }
    }
    
    /// Update hope meter time and check thresholds
    func updateHopeMeter() {
        guard isHopeMeterRunning else { return }
        
        // Update time left
        hopeMeterTimeLeft = max(0, hopeMeterTimeLeft - 1/60)  // Assuming 60fps updates
        
        // Check for specific time thresholds
        checkHopeMeterThresholds()
        
        // Check for hope meter running out
        if hopeMeterTimeLeft <= 0 {
            isHopeMeterRunning = false
            Task { @MainActor in
                await hopeMeterDidRunOut()
            }
        }
    }
}
