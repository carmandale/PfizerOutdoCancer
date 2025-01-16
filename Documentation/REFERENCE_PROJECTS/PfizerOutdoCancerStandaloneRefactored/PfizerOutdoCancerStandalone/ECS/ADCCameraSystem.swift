import ARKit
import Foundation
import OSLog
@preconcurrency import RealityKit
import SwiftUI

struct ADCCameraComponent: Component, Codable {
}

final class ADCCameraSystem: System {
    
    static let query = EntityQuery(where: .has(ADCCameraComponent.self))
    
    private let arkitSession = ARKitSession()
    private let worldTrackingProvider = WorldTrackingProvider()
    
    public init(scene: RealityKit.Scene) {
        ADCCameraComponent.registerComponent()
        setUpSession()
    }
    
    func setUpSession() {
        Task { [arkitSession, worldTrackingProvider] in
                do {
                    try await arkitSession.run([worldTrackingProvider])
                } catch {
                    os_log(.info, "ITR..Error: \(error)")
                }
        }
    }
    
    public func update(context: SceneUpdateContext) {
        let entities = context.entities(matching: Self.query, updatingSystemWhen: .rendering).map({ $0 })
        
        guard !entities.isEmpty,
              let pose = worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else { return }
        let cameraTransform = Transform(matrix: pose.originFromAnchorTransform)
        
        for entity in entities {
            entity.transform = cameraTransform
        }
    }
}
