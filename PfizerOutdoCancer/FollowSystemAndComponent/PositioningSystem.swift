/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
The system for following the device's position and updating the entity to move each time the scene rerenders.
*/

import RealityKit
import SwiftUI
import ARKit

/// A system that moves entities to the device's transform each time the scene rerenders.
@MainActor
public class PositioningSystem: System {
    // MARK: - Static Properties
    static let query = EntityQuery(where: .has(PositioningComponent.self))
    private static var sharedAppModel: AppModel?
    private let systemId = UUID()
    
    // Static method to set AppModel
    static func setAppModel(_ appModel: AppModel) {
        print("🔄 PositioningSystem.setAppModel called")
        sharedAppModel = appModel
    }
    
    // MARK: - System Initialization
    public required init(scene: RealityKit.Scene) {
        print("🎯 PositioningSystem \(systemId) initializing...")
    }
    
    // MARK: - System Update
    public func update(context: SceneUpdateContext) {
        // Get device anchor from TrackingSessionManager's worldTrackingProvider
        guard let appModel = Self.sharedAppModel,
              case .running = appModel.trackingManager.worldTrackingProvider.state,
              let deviceAnchor = appModel.trackingManager.worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else {
            return
        }
        
        // Position entities that need positioning
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var positioningComponent = entity.components[PositioningComponent.self],
                  positioningComponent.needsPositioning else { continue }
            
            // Position the entity
            if tryPositionEntity(entity: entity, component: &positioningComponent, deviceAnchor: deviceAnchor) {
                // Mark as positioned
                positioningComponent.needsPositioning = false
                entity.components[PositioningComponent.self] = positioningComponent
                print("✅ Successfully positioned entity: \(entity.name)")
            }
        }
    }
    
    // MARK: - Entity Positioning
    private func tryPositionEntity(entity: Entity, component: inout PositioningComponent, deviceAnchor: DeviceAnchor) -> Bool {
        let deviceTransform = deviceAnchor.originFromAnchorTransform
        let translation = deviceTransform.translation()
        
        let finalPosition = SIMD3<Float>(
            translation.x + component.offsetX,
            translation.y + component.offsetY,
            translation.z + component.offsetZ
        )
        
        entity.setPosition(finalPosition, relativeTo: nil)
        print("📍 Positioned entity '\(entity.name)' at \(finalPosition)")
        return true
    }
}

