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
    
    // Add system instance identifier
    private let systemId = UUID()
    
    // Static method to set AppModel
    static func setAppModel(_ appModel: AppModel) {
        print("🔄 PositioningSystem.setAppModel called with ARKitSession ID: \(appModel.arkitSessionId)")
        sharedAppModel = appModel
    }
    
    // MARK: - Tracking Properties
    private var arkitSession: ARKitSession
    private var worldTrackingProvider: WorldTrackingProvider
    private var hasPositioned = false
    private var isInitialized = false
    
    // MARK: - System Initialization
    public required init(scene: RealityKit.Scene) {
        print("🎯 PositioningSystem \(systemId) initializing...")
        
        if let appModel = Self.sharedAppModel {
            print("✅ Using AppModel's ARKitSession (ID: \(appModel.arkitSessionId))")
            self.arkitSession = appModel.arkitSession
            self.worldTrackingProvider = appModel.worldTrackingProvider
        } else {
            print("⚠️ No AppModel available, creating new ARKitSession")
            self.arkitSession = ARKitSession()
            self.worldTrackingProvider = WorldTrackingProvider()
        }
        
        initializeTracking()
    }
    
    private func initializeTracking() {
        Task {
            guard WorldTrackingProvider.isSupported else {
                print("❌ WorldTrackingProvider not supported")
                return
            }
            
            do {
                // Check provider state
                switch worldTrackingProvider.state {
                case .running:
                    print("⚠️ World tracking provider already running, skipping session start")
                    isInitialized = true
                    return
                case .stopped:
                    print("⚠️ World tracking provider is stopped, cannot restart")
                    return
                default:
                    break
                }
                
                print("🚀 Starting tracking with ARKitSession...")
                try await arkitSession.run([worldTrackingProvider])
                isInitialized = true
                
                // Check if we're using AppModel's session
                if let appModel = Self.sharedAppModel,
                   arkitSession === appModel.arkitSession {
                    print("✅ Confirmed using AppModel's ARKitSession")
                } else {
                    print("⚠️ Using different ARKitSession than AppModel")
                }
                
                print("✅ World tracking initialized successfully")
            } catch {
                print("❌ ARKit error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - System Update
    public func update(context: SceneUpdateContext) {
        // Only log first successful positioning
        if !hasPositioned && isInitialized {
            if case .running = worldTrackingProvider.state {
                if worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) != nil {
                    // print("📍 PositioningSystem \(systemId) first positioning attempt with ARKitSession")
                }
            }
        }
        
        guard !hasPositioned, isInitialized else { return }
        
        // First verify world tracking is running
        guard case .running = worldTrackingProvider.state else {
            print("⚠️ World tracking state: \(worldTrackingProvider.state)")
            return
        }
        
        // Then try to get device anchor
        guard let deviceAnchor = worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else {
            print("⏳ Waiting for device anchor...")
            return
        }
        
        // Position entities only once we have everything we need
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

