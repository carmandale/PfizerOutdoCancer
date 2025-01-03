//
//  SwirlingComponent.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 12/30/24.
//
import RealityKit
import Foundation


struct SwirlingComponent: Component {}

class SwirlingSystem: System {
    static let query = EntityQuery(where: .has(SwirlingComponent.self))
    
    public required init(scene: Scene) { }
    
    public func update(context: SceneUpdateContext) {
        context.scene.performQuery(Self.query).forEach { entity in
            updateEntityPosition(entity, deltaTime: Float(context.deltaTime))
        }
    }
    
    private func updateEntityPosition(_ entity: Entity, deltaTime: Float) {
        // Get the camera position
        let cameraPosition = SIMD3<Float>([0, 1.0, -0.25])
        
        // Calculate direction to camera
        let directionToCamera = (cameraPosition - entity.position).normalized()
        
        // Create more complex swirling motion
        let time = Float(Date().timeIntervalSince1970)
        
        // Primary swirl
        let swirl = SIMD3<Float>(
            sin(time * 2.0) * cos(time * 0.5),
            cos(time * 1.7) * sin(time * 0.3),
            sin(time * 1.3) * cos(time * 0.7)
        ) * 0.05  // Base amplitude
        
        // Combine movements with proper vector math
        let movement = (directionToCamera * 0.5 + swirl) * SIMD3(repeating: deltaTime)
        
        // Update position
        entity.position += movement
        
        // Smoother rotation
        if movement.length() > 0.001 {
            let smoothLookAtPoint = entity.position + movement * 2
            entity.look(at: smoothLookAtPoint, from: entity.position, relativeTo: nil)
        }
    }
}

//Add the Component to an Entity
//let entity = ModelEntity()
//entity.components[SwirlingComponent.self] = SwirlingComponent()

