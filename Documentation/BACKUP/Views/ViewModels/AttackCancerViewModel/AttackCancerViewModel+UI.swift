import SwiftUI
import RealityKit
import RealityKitContent

@Observable
@MainActor
class AttackCancerUIViewModel {
    var hitCounts: [Int] = []
    var requiredHits: [Int] = []
    var destroyedStates: [Bool] = []
    
    func setupUISync(for cell: Entity, index: Int) {
        cell.components.set(
            ClosureComponent { _ in
                guard let hitComponent = cell.components[HitCountComponent.self] else { return }
                
                // Ensure arrays are sized
                while self.hitCounts.count <= index {
                    self.hitCounts.append(0)
                    self.requiredHits.append(0)
                    self.destroyedStates.append(false)
                }
                
                // Update state
                self.hitCounts[index] = hitComponent.hitCount
                self.requiredHits[index] = hitComponent.requiredHits
                self.destroyedStates[index] = hitComponent.isDestroyed
            }
        )
    }
} 
