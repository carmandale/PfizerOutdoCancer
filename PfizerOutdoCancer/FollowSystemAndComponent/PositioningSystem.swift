/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
The system for following the device's position and updating the entity to move each time the scene rerenders.
*/

import Foundation
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
    
    // Simulator fallback values
    private static var isSimulatorMode: Bool = false
    private static var fallbackPosition: SIMD3<Float> = SIMD3<Float>(-0.0002527883, 0.9118354, 0.20180774)
    
    // Static method to set AppModel
    static func setAppModel(_ appModel: AppModel) {
        Logger.debug("🔄 PositioningSystem.setAppModel called")
        sharedAppModel = appModel
    }
    
    // Set simulator mode
    static func setSimulatorMode(_ enabled: Bool) {
        isSimulatorMode = enabled
        Logger.info("🧪 PositioningSystem simulator mode \(enabled ? "enabled" : "disabled")")
    }
    
    // Set fallback position for simulator
    static func setFallbackPosition(_ position: SIMD3<Float>) {
        fallbackPosition = position
        Logger.info("🧪 PositioningSystem fallback position set to \(position)")
    }
    
    // MARK: - System Initialization
    public required init(scene: RealityKit.Scene) {
        Logger.debug("🎯 PositioningSystem \(systemId) initializing...")
    }
    
    // MARK: - System Update
    public func update(context: SceneUpdateContext) {
        // Get current device position - either from tracking or fallback
        let devicePosition: SIMD3<Float>
        
        if Self.isSimulatorMode {
            // Use fallback position for simulator
            devicePosition = Self.fallbackPosition
            // Logger.debug("🧪 Using simulator fallback position: \(devicePosition)")
        } else {
            // Get device anchor from TrackingSessionManager's worldTrackingProvider
            guard let appModel = Self.sharedAppModel else {
                // Only log if AppModel is missing, as this indicates a setup issue
                Logger.error("❌ PositioningSystem: Missing AppModel reference")
                return
            }
            
            // Skip silently if tracking isn't running or no device anchor available
            guard case .running = appModel.trackingManager.worldTrackingProvider.state,
                  let deviceAnchor = appModel.trackingManager.worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else {
                return
            }
            
            let deviceTransform = deviceAnchor.originFromAnchorTransform
            devicePosition = deviceTransform.translation()
        }
        
        // Position entities that need positioning
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var positioningComponent = entity.components[PositioningComponent.self],
                  positioningComponent.needsPositioning,
                  !positioningComponent.isAnimating else { continue }
            
            // Only log if we're not already animating
            if !positioningComponent.isAnimating {
                Logger.debug("""
                
                🔄 Starting position update for entity '\(entity.name)'
                ├─ Current Position: \(entity.position(relativeTo: nil))
                ├─ Animated: \(positioningComponent.shouldAnimate ? "✅" : "❌")
                └─ Duration: \(positioningComponent.animationDuration)s
                """)
            }
            
            Task {
                // Set animating state immediately
                positioningComponent.isAnimating = true
                entity.components[PositioningComponent.self] = positioningComponent
                
                if await tryPositionEntity(entity: entity, component: &positioningComponent, devicePosition: devicePosition) {
                    // Wait for animation
                    if positioningComponent.shouldAnimate {
                        try? await Task.sleep(for: .seconds(positioningComponent.animationDuration))
                    }
                    
                    // Update final state
                    positioningComponent.isAnimating = false
                    positioningComponent.needsPositioning = false
                    entity.components[PositioningComponent.self] = positioningComponent
                    
                    Logger.debug("""
                    
                    ✨ Position update complete for '\(entity.name)'
                    ├─ Final Position: \(entity.position(relativeTo: nil))
                    └─ Status: Success
                    """)
                }
            }
        }
    }
    
    // MARK: - Entity Positioning
    private func tryPositionEntity(entity: Entity, component: inout PositioningComponent, devicePosition: SIMD3<Float>) async -> Bool {
        // Validate translation values
        let minValidDistance: Float = 0.3  // Minimum 0.3 meters from device
        let maxValidDistance: Float = 3.0   // Maximum 3 meters from device
        
        // Calculate the target position with offsets
        let targetPosition = SIMD3<Float>(
            devicePosition.x + component.offsetX,
            devicePosition.y + component.offsetY,
            devicePosition.z + component.offsetZ
        )
        
        // Calculate distance from device to target (including offsets)
        let distanceFromDevice = length(targetPosition - devicePosition)
        
        // Validate and adjust position if needed
        let finalPosition: SIMD3<Float>
        if distanceFromDevice < minValidDistance || distanceFromDevice > maxValidDistance {
            Logger.debug("""
            
            ⚠️ Invalid position detected for '\(entity.name)'
            ├─ Distance from device: \(distanceFromDevice)m
            ├─ Min allowed: \(minValidDistance)m
            └─ Max allowed: \(maxValidDistance)m
            """)
            
            // Calculate direction vector from device to target
            let direction = normalize(targetPosition - devicePosition)
            
            // Clamp distance to valid range
            let clampedDistance = simd_clamp(distanceFromDevice, minValidDistance, maxValidDistance)
            
            // Calculate new position at clamped distance
            finalPosition = devicePosition + (direction * clampedDistance)
            
            Logger.debug("✅ Adjusted to safe distance: \(clampedDistance)m")
        } else {
            finalPosition = targetPosition
        }
        
        Logger.debug("""
        
        📍 Positioning entity '\(entity.name)'
        ├─ From: \(entity.position)
        ├─ To: \(finalPosition)
        ├─ Offsets: [\(component.offsetX), \(component.offsetY), \(component.offsetZ)]
        ├─ Distance: \(distanceFromDevice)m
        └─ Method: \(component.shouldAnimate ? "Animated (\(component.animationDuration)s)" : "Immediate")
        """)
        
        if component.shouldAnimate {
            await entity.animateAbsolutePosition(
                to: finalPosition,
                duration: component.animationDuration,
                timing: .easeInOut,
                waitForCompletion: false
            )
        } else {
            entity.setPosition(finalPosition, relativeTo: nil)
        }
        
        Logger.debug("""
        
        ✨ Position update complete for '\(entity.name)'
        ├─ Final Position: \(entity.position(relativeTo: nil))
        └─ Status: Success
        """)
        
        return true
    }
}

