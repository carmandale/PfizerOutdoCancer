import ARKit
import Foundation
import OSLog
@preconcurrency import RealityKit

struct ADCSimpleBillboardComponent: Component, Codable {
}

final class ADCSimpleBillboardSystem: System {
    static var dependencies: [SystemDependency] = [.before(ADCCameraSystem.self)]
    
    public init(scene: RealityKit.Scene) {
        ADCSimpleBillboardComponent.registerComponent()
    }
    
    public func update(context: SceneUpdateContext) {
        guard let cameraEntity = context.entities(matching: EntityQuery(where: .has(ADCCameraComponent.self)), updatingSystemWhen: .rendering).map({ $0 }).first else {
            return
        }

        for entity in context.entities(matching: EntityQuery(where: .has(ADCSimpleBillboardComponent.self)), updatingSystemWhen: .rendering) {
            entity.look(at: cameraEntity.scenePosition,
                        from: entity.scenePosition,
                        relativeTo: nil,
                        forward: .positiveZ)
        }
    }
}
