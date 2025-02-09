import SwiftUI
import RealityKitContent
import RealityKit

extension AttackCancerViewModel {
    // MARK: - Notification Setup
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
              let _ = entity.components[CancerCellStateComponent.self] else {
            print("⚠️ Failed to unwrap required values in handleCancerCellUpdate")
            return
        }
        
        // Update game stats using cellParameters
        totalHits = cellParameters.reduce(0) { sum, params in
            sum + params.hitCount
        }
        print("📊 Total hits across all cells: \(totalHits)")
        
        let destroyedCount = cellParameters.filter { params in
            params.hitCount >= params.requiredHits
        }.count
        appModel.gameState.cellsDestroyed = destroyedCount
        print("💀 Total cells destroyed: \(destroyedCount)")
        
        // Check game conditions and notify state changes
        checkGameConditions()
        notifyGameStateChanged()
        notifyScoreChanged()
    }
    
    private func checkGameConditions() {
        // Check if all cells are destroyed
        if appModel.gameState.cellsDestroyed >= cellParameters.count {
            Task { @MainActor in
                // Instead of immediately ending, accelerate the hope meter
                print("🎯 All cells destroyed - accelerating hope meter")
                await appModel.accelerateHopeMeterToCompletion()
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
