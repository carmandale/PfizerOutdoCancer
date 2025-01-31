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
        
        // Proceed with existing cancer cell logic
        guard let scene = scene,
              let stateComponent = entity.components[CancerCellStateComponent.self],
              let cellID = stateComponent.parameters.cellID else {
            print("No scene available or no cell component/ID")
            return
        }
        print("Found cancer cell with ID: \(cellID)")
        
        guard let attachPoint = AttachmentSystem.getAvailablePoint(in: scene, forCellID: cellID) else {
            print("No available attach point found")
            // TODO: Handle no available attach point
            // if no attach point is available, spawn and launch an ADC and have it go into orbit and look for a cancer cell to attach to
            return
        }
        print("Found attach point: \(attachPoint.name)")
        
        AttachmentSystem.markPointAsOccupied(attachPoint)
        
        // Use the detected hand position if available, otherwise fall back to tap location
        let spawnPosition = handPosition ?? location
        await spawnADC(from: spawnPosition, targetPoint: attachPoint, forCellID: cellID)
    }
}
