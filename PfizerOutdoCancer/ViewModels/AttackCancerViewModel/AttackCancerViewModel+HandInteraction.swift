import SwiftUI
import RealityKit
import RealityKitContent

extension AttackCancerViewModel {
    // MARK: - Tap Handling
    func handleTap(on entity: Entity, location: SIMD3<Float>, in scene: RealityKit.Scene?) async {
        print("\n=== Tapped Entity ===")
        print("Entity name: \(entity.name)")
        print("Passed Location: \(location)")
        
        // If location is non-zero, use it (for tutorial ADCs)
        let spawnPosition: SIMD3<Float>
        if location != .zero {
            spawnPosition = location
            print("Using passed location for spawn: \(location)")
        } else {
            // Get pinch distances for both hands to determine which hand tapped
            let leftPinchDistance = handTracking.getPinchDistance(.left) ?? Float.infinity
            let rightPinchDistance = handTracking.getPinchDistance(.right) ?? Float.infinity
            
            // Determine which hand's position to use
            let handPosition: SIMD3<Float>?
            if leftPinchDistance < rightPinchDistance {
                handPosition = handTracking.getFingerPosition(.left)
                print("Left hand tap detected")
                print("Left hand position: \(String(describing: handPosition))")
            } else {
                handPosition = handTracking.getFingerPosition(.right)
                print("Right hand tap detected")
                print("Right hand position: \(String(describing: handPosition))")
            }
            
            guard let position = handPosition else {
                print("❌ No valid hand position available")
                return
            }
            spawnPosition = position
            print("Using hand position for spawn: \(spawnPosition)")
        }
        
        // Ensure we have a valid scene
        guard let scene = scene else {
            print("No valid scene available")
            return
        }
        
        // Validate spawn position before proceeding
        print("\n=== Spawn Position Validation ===")
        print("Final spawn position: \(spawnPosition)")
        print("Is valid: \(spawnPosition.x.isFinite && spawnPosition.y.isFinite && spawnPosition.z.isFinite)")
        print("Is non-zero: \(spawnPosition != .zero)")
        
        // Check if we can target a cancer cell
        if let stateComponent = entity.components[CancerCellStateComponent.self],
           let cellID = stateComponent.parameters.cellID,
           let attachPoint = AttachmentSystem.getAvailablePoint(in: scene, forCellID: cellID) {
            print("Found cancer cell with ID: \(cellID)")
            print("Found attach point: \(attachPoint.name)")
            print("Attach point world position: \(attachPoint.position(relativeTo: nil))")
            
            AttachmentSystem.markPointAsOccupied(attachPoint)
            await spawnADC(from: spawnPosition, targetPoint: attachPoint, forCellID: cellID)
        } else {
            // No valid cancer cell target - spawn untargeted ADC
            print("Spawning untargeted ADC")
            await spawnUntargetedADC(from: spawnPosition)
        }
    }

    func setupHandTracking(in content: RealityViewContent, attachments: RealityViewAttachments) {
        // Add the hand tracking content entity which includes the debug spheres
        content.add(handTracking.setupContentEntity())
        
        // Create a separate anchor for the HopeMeter UI
        let uiAnchor = AnchorEntity(.hand(.left, location: .aboveHand))
        content.add(uiAnchor)
        
        // if let attachmentEntity = attachments.entity(for: "HopeMeter") {
        //     attachmentEntity.components[BillboardComponent.self] = BillboardComponent()
        //     attachmentEntity.scale *= 0.6
        //     attachmentEntity.position.z -= 0.02
        //     uiAnchor.addChild(attachmentEntity)
        // }
    }
}
