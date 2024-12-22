import SwiftUI
import RealityKitContent
import RealityKit

extension AttackCancerViewModel {
    // MARK: - Notification Setup
    func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCancerCellUpdate),
            name: Notification.Name("UpdateCancerCell"),
            object: nil
        )
    }
    
    @objc func handleCancerCellUpdate(_ notification: Notification) {
        guard let entity = notification.userInfo?["entity"] as? Entity,
              let stateComponent = entity.components[CancerCellStateComponent.self],
              let cellID = stateComponent.parameters.cellID else {
            print("⚠️ Failed to unwrap required values in handleCancerCellUpdate")
            return
        }
        
        // Update game stats using cellParameters
        totalHits = cellParameters.reduce(0) { sum, params in
            sum + params.hitCount
        }
        print("📊 Total hits across all cells: \(totalHits)")
        
        cellsDestroyed = cellParameters.filter { params in
            params.hitCount >= params.requiredHits
        }.count
        print("💀 Total cells destroyed: \(cellsDestroyed)")
        
        // Check game conditions and notify state changes
        checkGameConditions()
        notifyGameStateChanged()
        notifyScoreChanged()
    }
    
    private func checkGameConditions() {
        // Check if all cells are destroyed
        if cellsDestroyed >= maxCancerCells {
            Task { @MainActor in
                endGame()
            }
        }
    }
    
    // MARK: - State Change Notifications
    private func notifyCellStateChanged() {
        // This will be handled by SwiftUI's @Observable
    }
    
    private func notifyGameStateChanged() {
        // This will be handled by SwiftUI's @Observable
    }
    
    private func notifyScoreChanged() {
        // This will be handled by SwiftUI's @Observable
    }
}
