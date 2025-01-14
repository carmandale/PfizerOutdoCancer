/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The system for following the device's position and updating the entity to move each time the scene rerenders.
*/

import RealityKit
import SwiftUI
import ARKit

/// A system that moves entities to the device's transform each time the scene rerenders.
public struct PositioningSystem: System {
    static let query = EntityQuery(where: .has(PositioningComponent.self))
    private let arkitSession = ARKitSession()
    private let worldTrackingProvider = WorldTrackingProvider()
    
    public init(scene: RealityKit.Scene) {
        runSession()
    }
    
    func runSession() {
        Task {
            do {
                try await arkitSession.run([worldTrackingProvider])
            } catch {
                print("Error: \(error). error starting world tracking session.")
            }
        }

    }

    // TODO: Add logic to position entities relative to the device's transform from @HeadPositionTracker
    
    public func update(context: SceneUpdateContext) {
        // Check whether the world-tracking provider is running.
        guard worldTrackingProvider.state == .running else { return }
        
        
    }
}

