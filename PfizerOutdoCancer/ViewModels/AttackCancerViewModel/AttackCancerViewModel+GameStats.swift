import SwiftUI
import RealityKitContent
import RealityKit

extension AttackCancerViewModel {
    // MARK: - Game Methods
    func resetGameState() {
        print("\n🔄 Resetting game stats:")
        print("  - Cells Destroyed: \(cellsDestroyed) → 0")
        print("  - Total ADCs: \(totalADCsDeployed) → 0")
        print("  - Total Taps: \(totalTaps) → 0")
        print("  - Total Hits: \(totalHits) → 0")

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
