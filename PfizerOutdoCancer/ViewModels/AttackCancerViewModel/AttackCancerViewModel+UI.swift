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

    func setupUIAttachments(in root: Entity, attachments: RealityViewAttachments, count: Int) {
        print("\n=== Setting up UI Attachments ===")
        print("Total attachments to create: \(count)")
        
        for i in 0..<count {
            print("Setting up attachment \(i)")
            if let meter = attachments.entity(for: "\(i)") {
                print("✅ Found meter entity for \(i)")
                if root.findEntity(named: "cancer_cell_\(i)") != nil {
                    print("✅ Found cancer cell \(i)")
                    root.addChild(meter)
                    meter.components[UIAttachmentComponent.self] = UIAttachmentComponent(attachmentID: i)
                    meter.components.set(BillboardComponent())
                    
                    print("✅ Added meter to cancer_cell_\(i) with components")
                } else {
                    print("❌ Could not find cancer cell \(i)")
                }
            } else {
                print("❌ Could not create meter entity for \(i)")
            }
        }
    }
} 
