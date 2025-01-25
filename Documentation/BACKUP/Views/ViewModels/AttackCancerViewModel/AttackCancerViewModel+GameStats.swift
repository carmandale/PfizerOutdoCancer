import SwiftUI
import RealityKitContent
import RealityKit

extension AttackCancerViewModel {
    // MARK: - Game Methods
    func resetGameState() {
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
        appModel.isTutorialStarted = true  // This will trigger the tutorial sequence
        
        appModel.currentPhase = .playing
        appModel.isInstructionsWindowOpen = true
        appModel.isHopeMeterUtilityWindowOpen = false  // Let the tutorial sequence open this at 24s
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
