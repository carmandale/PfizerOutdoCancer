//
//  ADCMovementSystem+Utils.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 2/3/25.
//

import RealityKit
import Foundation
import RealityKitContent

@MainActor
extension ADCMovementSystem {
    static func resetADC(entity: Entity, component: inout ADCComponent) {
        #if DEBUG
        print("\n=== Resetting ADC ===")
        print("Previous State: \(component.state)")
        print("Previous Target Cell ID: \(String(describing: component.targetCellID))")
        #endif
        
        // Reset ADC state and target information.
        component.state = .orbiting
        component.targetEntityID = nil
        component.targetCellID = nil
        component.startWorldPosition = nil
        component.targetWorldPosition = nil
        
        // Reset path tracking values.
        component.traveledDistance = 0
        component.pathLength = 0
        component.lookupTable = nil
        
        // Reset retargeting/interpolation values.
        component.previousTargetPosition = nil
        component.newTargetPosition = nil
        component.targetInterpolationProgress = 0
        component.previousPathLength = 0
        component.previousPathTangent = nil
        component.isRetargetedPath = false
        component.compositeProgress = 0
        
        // Stop any ongoing audio.
        entity.stopAllAudio()
        
        // --- NEW: Orbiting Setup ---
        // Set lower and more varied orbit parameters.
        let orbitRadius = Float.random(in: 2.0...3.0)       // Slightly lower orbit radius.
        let orbitHeight = Float.random(in: 0.5...1.0)         // Lower orbit height.
        let orbitSpeed = Float.random(in: 0.3...0.6)          // More variation in orbit speed.
        let orbitTheta = Float.random(in: 0...(2 * .pi))
        component.orbitRadius = orbitRadius
        component.orbitHeight = orbitHeight
        component.orbitSpeed = orbitSpeed
        component.orbitTheta = orbitTheta
        
        // Organic vertical oscillation parameters (with lower amplitude).
        component.verticalOscillationAmplitude = Float.random(in: 0.1...0.3)
        component.verticalOscillationFrequency = Float.random(in: 0.5...1.0)
        component.verticalOscillationPhase = Float.random(in: 0...(2 * .pi))
        
        // --- NEW: Smooth Transition into Orbiting ---
        // Capture the current position as the starting point.
        component.orbitTransitionStartPosition = entity.position(relativeTo: nil)
        // Reset transition progress.
        component.orbitTransitionProgress = 0.0
        // Increase the duration for a smoother transition.
        component.orbitTransitionDuration = 2.0  // For example, 2 seconds.
        
        // --- NEW: Tumbling Rotation Parameters ---
        // Reset the tumble angle and assign a random tumble speed.
        component.tumbleAngle = 0.0
        component.tumbleSpeed = Float.random(in: 0.5...1.5)  // Radians per second.
        
        // Disable collisions (if applicable).
        if var collisionComponent = entity.components[CollisionComponent.self] {
            collisionComponent.filter = CollisionFilter(group: collisionComponent.filter.group, mask: [])
            entity.components[CollisionComponent.self] = collisionComponent
        }
        
        entity.components[ADCComponent.self] = component
        
        #if DEBUG
        print("✅ ADC Reset Complete")
        print("New State: \(component.state)")
        #endif
    }
}