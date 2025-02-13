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
        
        // Ensure we have a valid scene
        guard let scene = scene else {
            print("No scene available")
            return
        }
        
        // Use hand position if available, otherwise use provided location
        let spawnPosition = handPosition ?? location
        
        // Check if we can target a cancer cell
        if let stateComponent = entity.components[CancerCellStateComponent.self],
           let cellID = stateComponent.parameters.cellID {
            print("Found cancer cell with ID: \(cellID)")
            
            // Use the new approach-aware getAvailablePoint
            if let attachPoint = AttachmentSystem.getAvailablePoint(in: scene, forCellID: cellID, approachPosition: spawnPosition) {
                print("Found attach point: \(attachPoint.name)")
                AttachmentSystem.markPointAsOccupied(attachPoint)
                await spawnADC(from: spawnPosition, targetPoint: attachPoint, forCellID: cellID)
            } else {
                print("No available attach point found")
                await spawnUntargetedADC(from: spawnPosition)
            }
        } else {
            // No valid cancer cell target - spawn untargeted ADC
        if Double.random(in: 0..<1) < 0.1 {
            print("Spawning untargeted ADC based on random chance")
            await spawnUntargetedADC(from: spawnPosition)
        } else {
            print("Skipping untargeted ADC spawn due to random chance")
        }
        }
    }

    func setupHandTracking(in content: RealityViewContent, attachments: RealityViewAttachments? = nil) {
        // Add the hand tracking content entity which includes the debug spheres
        content.add(appModel.trackingManager.handTrackingManager.setupContentEntity())
        
        // Create a separate anchor for the HopeMeter UI
//        let uiAnchor = AnchorEntity(.hand(.left, location: .aboveHand))
//        content.add(uiAnchor)
        
        // if let attachmentEntity = attachments.entity(for: "HopeMeter") {
        //     attachmentEntity.components[BillboardComponent.self] = BillboardComponent()
        //     attachmentEntity.scale *= 0.6
        //     attachmentEntity.position.z -= 0.02
        //     uiAnchor.addChild(attachmentEntity)
        // }
    }
}
