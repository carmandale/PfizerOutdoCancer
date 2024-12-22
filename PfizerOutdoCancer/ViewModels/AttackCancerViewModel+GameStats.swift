import SwiftUI
import RealityKitContent
import RealityKit

extension AttackCancerViewModel {
    // MARK: - Game Methods
    func startGame() {
        appModel.currentPhase = .playing
        cellsDestroyed = 0
        totalADCsDeployed = 0
        totalTaps = 0
        hopeMeterTimeLeft = hopeMeterDuration
        isHopeMeterRunning = true
        hasFirstADCBeenFired = false
    }
    
    func endGame() {
        appModel.currentPhase = .completed
        isHopeMeterRunning = false
    }
    
    func resetGameState() {
        // Reset all cell parameters
        for i in 0..<cellParameters.count {
            cellParameters[i].hitCount = 0
            cellParameters[i].isDestroyed = false
        }
        
        // Reset hope meter
        hopeMeterTimeLeft = hopeMeterDuration
        isHopeMeterRunning = false
        
        appModel.currentPhase = .playing
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
