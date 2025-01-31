import SwiftUI
import RealityKit
import RealityKitContent

extension AttackCancerViewModel {
    // MARK: - Tap Handling
    func handleTap(on entity: Entity, location: SIMD3<Float>, in scene: RealityKit.Scene?) async {
        print("\n=== Tapped Entity ===")
        print("Entity name: \(entity.name)")
//        appModel.assetLoadingManager.inspectEntityHierarchy(entity)
        
        // Get pinch distances for both hands to determine which hand tapped
        let leftPinchDistance = handTracking.getPinchDistance(.left) ?? Float.infinity
        let rightPinchDistance = handTracking.getPinchDistance(.right) ?? Float.infinity
        
        // Determine which hand's position to use
        let handPosition: SIMD3<Float>?
        if leftPinchDistance < rightPinchDistance {
            handPosition = handTracking.getFingerPosition(.left)
            print("Left hand tap detected")
        } else {
            handPosition = handTracking.getFingerPosition(.right)
            print("Right hand tap detected")
        }
        
        // Ensure we have a valid hand position and scene
        guard let spawnPosition = handPosition, let scene = scene else {
            print("No valid hand position or scene available")
            return
        }
        
        // Check if we can target a cancer cell
        if let stateComponent = entity.components[CancerCellStateComponent.self],
           let cellID = stateComponent.parameters.cellID,
           let attachPoint = AttachmentSystem.getAvailablePoint(in: scene, forCellID: cellID) {
            print("Found cancer cell with ID: \(cellID)")
            print("Found attach point: \(attachPoint.name)")
            
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
