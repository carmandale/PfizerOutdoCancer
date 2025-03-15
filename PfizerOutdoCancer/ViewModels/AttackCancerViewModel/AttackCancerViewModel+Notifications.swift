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
            let totalGameCells = cellParameters.filter { !$0.isTutorialCell }.count
            
            if totalGameCells > 0, cellsDestroyed >= totalGameCells {
                print("✅✅✅ ALL GAME CELLS DESTROYED! Condition met!")
                Task { @MainActor in
                    // Only play if we haven't played the victory sequence yet
                    if !self.hasPlayedVictorySequence {
                        self.hasPlayedVictorySequence = true
                        print("🎯 All game cells destroyed - accelerating hope meter")
                        await appModel.accelerateHopeMeterToCompletion()
                        try? await Task.sleep(for: .milliseconds(100))
                        // Only play magic_zing if it hasn't already been played as part of the ending sequence
                        if !self.hasPlayedEndingSequence {
                            await self.playEndSound("magic_zing", forSequence: .ending)
                        }
                        await self.playVictorySequence()
                        try? await Task.sleep(for: .milliseconds(1000))
                        await appModel.transitionToPhase(.completed)
                    }
                }
            }
        }

    // Optionally, if there's an area where the hope meter runs out, add a call there as well:
    func hopeMeterDidRunOut() async {
            Task { @MainActor in
                if !self.hasPlayedVictorySequence {
                    self.hasPlayedVictorySequence = true
                    Logger.audio("\n=== playing end sound ===\n")
                    await self.playVictorySequence()
                }
            }
        }
    
    /// Monitor hope meter time and trigger events at specific thresholds
    func checkHopeMeterThresholds() {
            guard isGameActive else { return }
            
            // Use a tighter threshold window and check the flag
            if hopeMeterTimeLeft <= 19 && hopeMeterTimeLeft > 18.9 && !hasPlayedEndingSequence {
                Logger.audio("Hope meter at 19 seconds - triggering ending sequence")
                Task { @MainActor in
                    self.hasPlayedEndingSequence = true
                    await playEndingSequence()
                }
            }
        }
    
    /// Update hope meter time and check thresholds
    func updateHopeMeter() {
            guard isHopeMeterRunning else { return }
            
            hopeMeterTimeLeft = max(0, hopeMeterTimeLeft - 1/60)
            
            // Check thresholds only if sequences haven't played yet
            if !hasPlayedEndingSequence || !hasPlayedVictorySequence {
                checkHopeMeterThresholds()
            }
            
            if hopeMeterTimeLeft <= 0 {
                isHopeMeterRunning = false
                Task { @MainActor in
                    await hopeMeterDidRunOut()
                }
            }
        }
}
