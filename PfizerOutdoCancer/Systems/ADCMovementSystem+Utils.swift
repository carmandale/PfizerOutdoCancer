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
        component.state = .idle
        component.targetEntityID = nil
        component.targetCellID = nil
        component.startWorldPosition = nil
        component.targetWorldPosition = nil
        
        // Reset arc-length and path tracking values.
        component.traveledDistance = 0
        component.pathLength = 0
        component.lookupTable = nil
        
        // Reset retargeting/interpolation values.
        component.previousTargetPosition = nil
        component.newTargetPosition = nil
        component.targetInterpolationProgress = 0
        
        // Reset additional properties related to retargeting/composite paths.
        component.previousPathLength = 0
        component.previousPathTangent = nil
        component.isRetargetedPath = false
        component.compositeProgress = 0
        
        // Stop any ongoing animations or audio.
        entity.stopAllAnimations()
        entity.stopAllAudio()
        
        #if DEBUG
        print("✅ ADC Reset Complete")
        print("New State: \(component.state)")
        #endif
    }
}