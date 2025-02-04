import SwiftUI
import RealityKitContent
import RealityKit

extension AttackCancerViewModel {
    // MARK: - Game Methods
    
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
