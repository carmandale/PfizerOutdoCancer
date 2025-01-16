import ARKit
import Foundation
import OSLog
@preconcurrency import RealityKit


/// Adjusts the position and orientation of an entity relative to a camera based on specified parameters.
///
/// - Parameters:
///   - offset: A vector that specifies a constant positional offset from the entity or camera.
///   - axisToFollow: A vector used to determine which axes should be followed. For example:
///     - `[0, 1, 0]` will follow the Y-axis, causing the entity to maintain a height equal to the camera’s height plus the offset.
///     - `[0, 0, 0]` fixes the entity’s position (while still enabling billboarding).
///     - `[1, 1, 1]` attaches the entity at a fixed distance (offset) from the camera on all axes.
///
///     **Note:** Currently, only values of `0` or `1` are valid for each component. This may change to booleans in the future.
///
///   - initializePositionOnlyOnce: When `true`, the entity’s initial position is set once—using the first non-zero camera position—then remains constant. When `false`, the entity’s position is updated every frame if `axisToFollow` is not `.zero`.
///
///   - isBillboardEnabled: When `true`, the entity will be reoriented every frame to face the user along the X and Y axes.
///   
struct ADCBillboardComponent: Component, Codable {
    var offset: SIMD3<Float> = .zero
    var axisToFollow: SIMD3<Int> = .zero
    var initializePositionOnlyOnce: Bool = false
    var isBillboardEnabled: Bool = false
    var isPositionInitialized: Bool = false
}

final class ADCBillboardSystem: System {
    static var dependencies: [SystemDependency] = [.before(ADCCameraSystem.self)]
    
    public init(scene: RealityKit.Scene) {
        ADCBillboardComponent.registerComponent()
    }
    
    public func update(context: SceneUpdateContext) {
        guard let cameraEntity = context.entities(matching: EntityQuery(where: .has(ADCCameraComponent.self)), updatingSystemWhen: .rendering).map({ $0 }).first else {
            return
        }

        for entity in context.entities(matching: EntityQuery(where: .has(ADCBillboardComponent.self)), updatingSystemWhen: .rendering) {
            guard var billboard = entity.components[ADCBillboardComponent.self] else { continue }
            if !billboard.isPositionInitialized {
                if cameraEntity.position != .zero {
                    billboard.isPositionInitialized = true
                }
                entity.components.set(billboard)
                let newPosition: SIMD3<Float> = [billboard.axisToFollow.x == 1 ? cameraEntity.position.x : 0,
                                                 billboard.axisToFollow.y == 1 ? cameraEntity.position.y : 0,
                                                 billboard.axisToFollow.z == 1 ? cameraEntity.position.z : 0] + billboard.offset
                entity.position = newPosition
            } else {
                if !billboard.initializePositionOnlyOnce {
                    let newPosition: SIMD3<Float> = [billboard.axisToFollow.x == 1 ? cameraEntity.position.x : 0,
                                                     billboard.axisToFollow.y == 1 ? cameraEntity.position.y : 0,
                                                     billboard.axisToFollow.z == 1 ? cameraEntity.position.z : 0] + billboard.offset
                    
                    entity.position = newPosition
                }
            }
            if billboard.isBillboardEnabled {
                entity.look(at: cameraEntity.scenePosition,
                            from: entity.scenePosition,
                            relativeTo: nil,
                            forward: .positiveZ)
            }

        }
    }
}
