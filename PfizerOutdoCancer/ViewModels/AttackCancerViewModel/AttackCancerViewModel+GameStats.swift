import SwiftUI
import RealityKitContent
import RealityKit

extension AttackCancerViewModel {
    // MARK: - Game Methods

    /// Resets game state variables to their initial values without affecting entities or scene content.
    /// Use this when you want to restart the game state while keeping the current scene setup.
    ///
    /// Responsibilities:
    /// - Resets game statistics (scores, counters)
    /// - Resets state flags (tutorial state, game phase)
    /// - Resets head positioning state
    /// - Does NOT modify any entities or scene content
    /// - Does NOT affect system connections or subscriptions
    ///
    /// Call this when:
    /// - Starting a new game session
    /// - Restarting after game over
    /// - Resetting tutorial state
    func resetGameState() {
        Logger.debug("""
        
        🔄 Resetting Game State
        ├─ Cells Destroyed: \(cellsDestroyed) → 0
        ├─ Total ADCs: \(totalADCsDeployed) → 0
        ├─ Total Taps: \(totalTaps) → 0
        ├─ Total Hits: \(totalHits) → 0
        └─ Head Positioning: Resetting tracking state
        """)

        cellsDestroyed = 0
        totalADCsDeployed = 0
        totalTaps = 0
        totalHits = 0
        
        hopeMeterTimeLeft = hopeMeterDuration
        isHopeMeterRunning = false
        hasFirstADCBeenFired = false

        // Reset all cell parameters
        for i in 0..<cellParameters.count {
            cellParameters[i].hitCount = 0
            cellParameters[i].isDestroyed = false
        }
        
        // Reset head positioning state
        isRootSetupComplete = false
        isEnvironmentSetupComplete = false
        isHeadTrackingRootReady = false
        shouldUpdateHeadPosition = false
        isPositioningComplete = false
        isTutorialAlertVisible = false
        isPinchAnimationVisible = false
        
        Logger.debug("""
        
        🎯 Head Positioning Reset Complete
        ├─ Root Setup: \(isRootSetupComplete ? "✅" : "❌")
        ├─ Environment: \(isEnvironmentSetupComplete ? "✅" : "❌")
        ├─ Head Tracking: \(isHeadTrackingRootReady ? "✅" : "❌")
        └─ Update Pending: \(shouldUpdateHeadPosition ? "✅" : "❌")
        """)
        
        // Reset hope meter
        hopeMeterTimeLeft = hopeMeterDuration
        isHopeMeterRunning = false
        
        // Reset tutorial state to match first play
        tutorialComplete = false
        appModel.isTutorialStarted = false  // This will trigger the tutorial sequence
        isTestFireActive = false
        testFireComplete = false
        readyToStartGame = false
        isSetupComplete = false
        
        // Reset audio sequence flags
        hasPlayedEndingSequence = false
        hasPlayedVictorySequence = false
        hasPlayedGreatJob = false
        Logger.audio("✅ Reset all audio sequence flags")
        
        appModel.currentPhase = .playing
        appModel.isInstructionsWindowOpen = true
        appModel.isHopeMeterUtilityWindowOpen = false  // Let the tutorial sequence open this at 24s

        print("🔄 Reset tutorial state: isTutorialStarted: \(appModel.isTutorialStarted), tutorialComplete: \(tutorialComplete), isTestFireActive: \(isTestFireActive), readyToStartGame: \(readyToStartGame)")

    }
    
    // MARK: - ADC Tracking
    func incrementADCsDeployed() {
        totalADCsDeployed += 1
    }
    
    var score: Int {
        // Base score from destroyed cells
        let baseScore = cellsDestroyed * 100
        
        // Efficiency penalty based on ADCs used
        let efficiency = totalADCsDeployed > 0 ? Float(cellsDestroyed) / Float(totalADCsDeployed) : 0
        let efficiencyBonus = Int(efficiency * 50)
        
        return baseScore + efficiencyBonus
    }
}
