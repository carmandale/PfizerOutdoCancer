// ADCMovementSystem+Retargeting.swift

import RealityKit
import Foundation
import RealityKitContent

@MainActor
extension ADCMovementSystem {
    
    static func retargetADC(_ entity: Entity,
                            _ adcComponent: inout ADCComponent,
                            currentPosition: SIMD3<Float>,
                            in scene: Scene) -> Bool {
        guard let (newTarget, newCellID) = findNewTarget(for: entity, currentPosition: currentPosition, in: scene) else {
            print("⚠️ No valid targets found for retargeting")
            return false
        }
        
        print("🎯 Retargeting ADC to new cancer cell (ID: \(newCellID))")
        
        if adcComponent.targetCellID == newCellID {
            print("⚠️ Attempting to retarget to same cell - skipping")
            return false
        }
        
        if let currentTargetID = adcComponent.targetEntityID,
           let currentTarget = scene.findEntity(id: currentTargetID) {
            adcComponent.previousTargetPosition = currentTarget.position(relativeTo: nil)
            adcComponent.newTargetPosition = newTarget.position(relativeTo: nil)
            adcComponent.targetInterpolationProgress = 0
        }
        
        adcComponent.targetEntityID = newTarget.id
        adcComponent.targetCellID = newCellID
        
        if var attachPoint = newTarget.components[AttachmentPoint.self] {
            attachPoint.isOccupied = true
            newTarget.components[AttachmentPoint.self] = attachPoint
            print("✅ Marked attachment point as occupied")
        }
        
        // Reinitialize the lookup table for the new target curve.
        if let start = adcComponent.startWorldPosition {
            let newTargetPosition = newTarget.position(relativeTo: nil)
            let distance = length(newTargetPosition - start)
            let midPoint = mix(start, newTargetPosition, t: 0.5)
            let heightOffset = distance * 0.5 * (adcComponent.arcHeightFactor ?? 1.0)
            let controlPoint = midPoint + SIMD3<Float>(0, heightOffset, 0)
            let lookup = buildLookupTableForQuadraticBezier(start: start, control: controlPoint, end: newTargetPosition, samples: Self.numLookupSamples)
            adcComponent.lookupTable = lookup
            adcComponent.previousPathLength = adcComponent.pathLength
            adcComponent.pathLength = lookup.last ?? 0.0
            if adcComponent.previousPathLength > 0 {
                adcComponent.traveledDistance = (adcComponent.traveledDistance / adcComponent.previousPathLength) * adcComponent.pathLength
            }
        }
        
        return true
    }
    
    static func validateTarget(_ targetEntity: Entity, _ adcComponent: ADCComponent, in scene: Scene) -> Bool {
        if targetEntity.components[PositioningComponent.self] != nil {
            return true
        }
        
        if targetEntity.parent == nil {
            print("\n=== ADC RETARGET (Target Lost) ===")
            print("Target attachment point has been removed from scene")
            return false
        }
        
        guard let cancerCell = findParentCancerCell(for: targetEntity, in: scene) else {
            print("\n=== ADC RETARGET (Cancer Cell Lost) ===")
            print("Parent cancer cell no longer exists")
            return false
        }
        
        guard let stateComponent = cancerCell.components[CancerCellStateComponent.self],
              let cellID = adcComponent.targetCellID else {
            print("\n=== ADC RETARGET (Invalid State) ===")
            print("Missing state component or target cell ID")
            return false
        }
        
        let parameters = stateComponent.parameters
        
        if parameters.isDestroyed {
            print("\n=== ADC RETARGET (Cell Destroyed) ===")
            print("Cell ID: \(cellID)")
            print("Hit Count: \(parameters.hitCount)/\(parameters.requiredHits)")
            return false
        }
        
        if parameters.hitCount >= parameters.requiredHits {
            print("\n=== ADC RETARGET (Cell Complete) ===")
            print("Cell ID: \(cellID)")
            print("Hit Count: \(parameters.hitCount)/\(parameters.requiredHits)")
            return false
        }
        
        if parameters.cellID == cellID &&
            !parameters.isDestroyed &&
            parameters.hitCount < parameters.requiredHits {
            return true
        }
        
        print("\n=== ADC RETARGET (Target Invalid) ===")
        print("Cell ID: \(cellID)")
        print("Hit Count: \(parameters.hitCount)/\(parameters.requiredHits)")
        print("Is Destroyed: \(parameters.isDestroyed)")
        return false
    }
    
    /// Calculates a score for an attachment point based on its position and orientation relative to an approach position
    /// - Parameters:
    ///   - attachPosition: World position of the attachment point
    ///   - cellCenter: World position of the cell center
    ///   - approachPosition: Position from which the ADC is approaching
    ///   - minDistance: Minimum allowed distance (to prevent too-close targeting)
    /// - Returns: A score where higher values indicate better targets, or nil if the target is invalid
    @MainActor
    public static func calculateAttachmentScore(
        attachPosition: SIMD3<Float>,
        cellCenter: SIMD3<Float>,
        approachPosition: SIMD3<Float>,
        minDistance: Float = 0.3
    ) -> Float? {
        let distance = length(attachPosition - approachPosition)
        
        // Skip if the target is too close (prevent sharp turns)
        if distance < minDistance {
            return nil
        }
        
        // Base score on inverse distance (closer is better, but not too close)
        var score = 1.0 / max(distance, minDistance)
        
        // Factor in the facing direction of the antigen
        let antigenDirection = simd_normalize(attachPosition - cellCenter)
        let approachVector = simd_normalize(approachPosition - cellCenter)
        let dotProduct = simd_dot(antigenDirection, approachVector)
        
        // Adjust score based on how well the antigen faces the approach vector
        // (dotProduct + 1) * 2.0 maps the dot product from [-1,1] to [0,4]
        score *= (dotProduct + 1) * 2.0
        
        return score
    }

    static func findNewTarget(for adcEntity: Entity, currentPosition: SIMD3<Float>, in scene: Scene) -> (Entity, Int)? {
        let query = EntityQuery(where: .has(AttachmentPoint.self))
        var bestScore: Float = -Float.infinity
        var bestTarget: (Entity, Int)? = nil
        
        let entities = scene.performQuery(query)
        
        for entity in entities {
            guard let attachComponent = entity.components[AttachmentPoint.self],
                  !attachComponent.isOccupied else {
                continue
            }
            
            guard let cancerCell = findParentCancerCell(for: entity, in: scene),
                  let stateComponent = cancerCell.components[CancerCellStateComponent.self],
                  let cellID = stateComponent.parameters.cellID,
                  !stateComponent.parameters.isDestroyed else {
                continue
            }
            
            if stateComponent.parameters.hitCount >= stateComponent.parameters.requiredHits {
                continue
            }
            
            let attachPosition = entity.position(relativeTo: nil)
            let cellCenter = cancerCell.position(relativeTo: nil)
            
            guard let score = Self.calculateAttachmentScore(
                attachPosition: attachPosition,
                cellCenter: cellCenter,
                approachPosition: currentPosition
            ) else { continue }
            
            // print("📊 Antigen Score - Distance: \(length(attachPosition - currentPosition)), Score: \(score)")
            
            if score > bestScore {
                bestScore = score
                bestTarget = (entity, cellID)
                print("✨ New best target found - Score: \(score)")
            }
        }
        
        if let target = bestTarget {
            print("\n🎯 Selected target:")
            print("Cell ID: \(target.1)")
            print("Attachment Point: \(target.0.name)")
            print("Final Score: \(bestScore)")
        }
        
        return bestTarget
    }
    
    // --- Re-add findParentCancerCell ---
    static func findParentCancerCell(for attachmentPoint: Entity, in scene: Scene) -> Entity? {
        var current = attachmentPoint
        while let parent = current.parent {
            if parent.components[CancerCellStateComponent.self] != nil {
                return parent
            }
            current = parent
        }
        return nil
    }
}
