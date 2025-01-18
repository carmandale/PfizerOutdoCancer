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
    
    // Instance state tracking
    private var isInitialized = false
    private var hasPositioned = false
    
    // Static method to set AppModel
    static func setAppModel(_ appModel: AppModel) {
        print("🔄 PositioningSystem.setAppModel called")
        sharedAppModel = appModel
    }
    
    // MARK: - System Initialization
    public required init(scene: RealityKit.Scene) {
        print("🎯 PositioningSystem \(systemId) initializing...")
    }
    
    // Remove initializeTracking() - tracking is handled by TrackingSessionManager
    
    // MARK: - System Update
    public func update(context: SceneUpdateContext) {
        guard !hasPositioned else { return }
        
        // Get device anchor from TrackingSessionManager's worldTrackingProvider
        guard let appModel = Self.sharedAppModel,
              case .running = appModel.trackingManager.worldTrackingProvider.state,
              let deviceAnchor = appModel.trackingManager.worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else {
            return
        }
        
        // Position entities
        if tryPositionEntities(deviceAnchor: deviceAnchor, context: context) {
            hasPositioned = true
            print("✅ Successfully positioned entities")
        }
    }
    
    // MARK: - Entity Positioning
    private func tryPositionEntities(deviceAnchor: DeviceAnchor, context: SceneUpdateContext) -> Bool {
        let deviceTransform = deviceAnchor.originFromAnchorTransform
        let translation = deviceTransform.translation()
        
        var didPositionAny = false
        
        // Update all entities with PositioningComponent
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard let positioningComponent = entity.components[PositioningComponent.self] else { continue }
            
            let finalPosition = SIMD3<Float>(
                translation.x + positioningComponent.offsetX,
                translation.y + positioningComponent.offsetY,
                translation.z + positioningComponent.offsetZ
            )
            
            entity.setPosition(finalPosition, relativeTo: nil)
            print("📍 Positioned entity '\(entity.name)' at \(finalPosition)")
            didPositionAny = true
        }
        
        return didPositionAny
    }
}

