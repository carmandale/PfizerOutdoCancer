//
//  RotationSystem.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 1/4/25.
//

import Foundation
import RealityKit


public struct RotationComponent: Component, Codable {
    public var rotationAxis: RotationAxis = .yAxis
    public var speed: Float = 1.0

    public var axis: SIMD3<Float> {
        return rotationAxis.axis
    }
    
    public init() {}
}

@MainActor
final class RotationSystem: System {
    static let query = EntityQuery(where: .has(RotationComponent.self))
    
    init(scene: Scene) {}
    
    public func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            /// Ensure the component is found.
            guard let component = entity.components[RotationComponent.self] else { continue }
            /// If the entity has a zero speed ignore it.
            if component.speed == 0.0 { continue }
            /// Set the orientation of the entity relative to itself, based on
            /// the speed and change in the time base.
            entity.orientation *= simd_quatf(angle: component.speed * Float(context.deltaTime),
                                             axis: component.axis)
        }
    }
    
    
}
