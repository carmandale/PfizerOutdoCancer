/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that enables world tracking and retrieves the transform of the device.
*/

import SwiftUI
import ARKit
import RealityKit

enum WorldTrackingError: Error {
    case trackingFailed
}

/// The `HeadPositionTracker` class starts a world-tracking session and gets the device's pose and anchors.
@Observable class HeadPositionTracker {
    /// The instance of the `ARKitSession` for world tracking.
    let arSession = ARKitSession()
    
    /// The instance of a new `WorldTrackingProvider` for world tracking.
    let worldTracking = WorldTrackingProvider()

    /// Simple private property since this is internal state
    private var isInitialized = false
    
    /// The initializer for the tracker to check through the requirements for world tracking
    /// and start the world-tracking session.
    init() {
        // Remove initialization from init
    }
    
    /// Ensure the tracker is initialized
    func ensureInitialized() async throws {
        // If already initialized, return immediately
        guard !isInitialized else { return }
        
        // Check whether the device supports world tracking
        guard WorldTrackingProvider.isSupported else {
            print("WorldTrackingProvider is not supported on this device")
            throw WorldTrackingError.trackingFailed
        }
        
        do {
            // Attempt to start an ARKit session with the world-tracking provider
            try await arSession.run([worldTracking])
            print("Successfully started ARKit session with world tracking")
            
            // Wait a short moment for the world tracking to fully initialize
            try await Task.sleep(nanoseconds: 500_000_000) // 500ms
            
            isInitialized = true
        } catch let error as ARKitSession.Error {
            print("Encountered an error while running providers: \(error.localizedDescription)")
            throw error
        } catch {
            print("Encountered an unexpected error: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Get the current position of the device.
    func originFromDeviceTransform() -> simd_float4x4? {
        /// The anchor of the device at the current time.
        guard let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else {
            return nil
        }
            
        // Return the device's transform.
        return deviceAnchor.originFromAnchorTransform
    }
    
    /// Position an entity relative to the user based on the current device transform
    /// - Parameters:
    ///   - entity: The entity to position
    ///   - offset: The offset vector relative to the user's position (default: [0, 0, -1])
    func positionEntityRelativeToUser(_ entity: Entity?, offset: SIMD3<Float> = [0, 0, -1]) {
        if let deviceTransform = originFromDeviceTransform() {
            let translation = deviceTransform.translation()
            print("positioning entity according to device transform")
            entity?.setPosition([
                translation.x + offset.x,
                translation.y + offset.y,
                translation.z + offset.z
            ], relativeTo: nil)
        }
    }
    
    /// Convenience method to position an entity directly in front of the user
    /// - Parameters:
    ///   - entity: The entity to position
    ///   - distance: Distance in front of the user (negative values are forward)
    func positionEntityInFrontOfUser(_ entity: Entity?, distance: Float = -1.0) {
        positionEntityRelativeToUser(entity, offset: [0, 0, distance])
    }
}
