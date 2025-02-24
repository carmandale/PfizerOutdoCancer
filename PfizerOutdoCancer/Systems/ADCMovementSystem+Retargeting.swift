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
        // Find new target
        Logger.debug("Retargeting ADC - Entity: \(entity.name), State: \(adcComponent.state), Current Position: \(currentPosition)")
        guard let (newTarget, newCellID) = findNewTarget(for: entity, currentPosition: currentPosition, in: scene) else {
            #if DEBUG
            Logger.debug("⚠️ No valid targets found for retargeting")
            #endif
            return false
        }
        
        #if DEBUG
        Logger.debug("🎯 Retargeting ADC to new cancer cell (ID: \(newCellID))")
        #endif
        
        // Skip if targeting same cell
        if adcComponent.targetCellID == newCellID {
            #if DEBUG
            Logger.debug("⚠️ Attempting to retarget to same cell - skipping")
            #endif
            return false
        }
        
        // Check that the new target is sufficiently far from current position
        let newTargetPos = newTarget.position(relativeTo: nil)
        let distanceToNewTarget = length(newTargetPos - currentPosition)
        let minRequiredDistance: Float = 0.3 // Match the scoring function's minimum distance
        
        if distanceToNewTarget < minRequiredDistance {
            #if DEBUG
            Logger.debug("\n⚠️ Target Distance Check Failed:")
            Logger.debug("New target \(newTarget.name) is too close to current position")
            Logger.debug("Distance to target: \(distanceToNewTarget)")
            Logger.debug("Required minimum distance: \(minRequiredDistance)")
            #endif
            return false
        } else {
            #if DEBUG
            Logger.debug("\n✅ Target Distance Check Passed:")
            Logger.debug("Distance to new target: \(distanceToNewTarget)")
            Logger.debug("Current position: \(currentPosition)")
            Logger.debug("Target position: \(newTargetPos)")
            #endif
        }
        
        // Store current target position and set up interpolation
        if let currentTargetID = adcComponent.targetEntityID,
           let currentTarget = scene.findEntity(id: currentTargetID) {
            // Store the current path length before updating
            adcComponent.previousPathLength = adcComponent.pathLength
            
            #if DEBUG
            Logger.debug("\n=== Previous Path Info ===")
            Logger.debug("Previous Path Length: \(adcComponent.pathLength)")
            Logger.debug("Previous Progress: \(adcComponent.traveledDistance / adcComponent.pathLength)")
            Logger.debug("Previous Target Position: \(currentTarget.position(relativeTo: nil))")
            Logger.debug("Previous Target Distance: \(length(currentTarget.position(relativeTo: nil) - currentPosition))")
            #endif
            
            // Set up target interpolation using transform snapshots
            let currentTransform = currentTarget.transformMatrix(relativeTo: nil)
            let newTransform = newTarget.transformMatrix(relativeTo: nil)
            
            adcComponent.previousTargetPosition = currentTransform.translation()
            adcComponent.newTargetPosition = newTransform.translation()
            adcComponent.targetInterpolationProgress = 0
            
            #if DEBUG
            Logger.debug("\n=== Starting Retarget ===")
            Logger.debug("From: \(currentTarget.name) to: \(newTarget.name)")
            Logger.debug("Current Distance Traveled: \(adcComponent.traveledDistance)")
            Logger.debug("Current Path Length: \(adcComponent.pathLength)")
            Logger.debug("Current Progress: \(adcComponent.traveledDistance / adcComponent.pathLength)")
            Logger.debug("New Target Distance: \(length(newTarget.position(relativeTo: nil) - currentPosition))")
            Logger.debug("Interpolation Start Position: \(currentPosition)")
            #endif
        }
        
        // Update component with new target info using proper component update pattern
        adcComponent.targetEntityID = newTarget.id
        adcComponent.targetCellID = newCellID
        
        // Update attachment point using proper component update pattern
        if let attachPoint = newTarget.components[AttachmentPoint.self] {
            var updatedAttachPoint = attachPoint
            updatedAttachPoint.isOccupied = true
            newTarget.components[AttachmentPoint.self] = updatedAttachPoint
            #if DEBUG
            Logger.debug("✅ Marked attachment point as occupied")
            #endif
        }
        
        return true
    }
    
    static func validateTarget(_ targetEntity: Entity, _ adcComponent: ADCComponent, in scene: Scene) -> Bool {
        // Check if this is an untargeted spawn point
        if let attachPoint = targetEntity.components[AttachmentPoint.self],
           attachPoint.isUntargeted {
            return true
        }
        
        // The rest of the validation is for cancer cell targets
        if targetEntity.parent == nil {
            #if DEBUG
            Logger.debug("\n=== ADC RETARGET (Target Lost) ===")
            Logger.debug("Target attachment point has been removed from scene")
            #endif
            return false
        }
        
        // Use proper error handling for component access
        guard let cancerCell = findParentCancerCell(for: targetEntity, in: scene),
              let stateComponent = cancerCell.components[CancerCellStateComponent.self],
              let cellID = adcComponent.targetCellID else {
            #if DEBUG
            Logger.debug("\n=== ADC RETARGET (Invalid State) ===")
            Logger.debug("Missing required components or target cell ID")
            #endif
            return false
        }
        
        let parameters = stateComponent.parameters
        
        if parameters.isDestroyed {
            #if DEBUG
            Logger.debug("\n=== ADC RETARGET (Cell Destroyed) ===")
            Logger.debug("Cell ID: \(cellID)")
            Logger.debug("Hit Count: \(parameters.hitCount)/\(parameters.requiredHits)")
            #endif
            return false
        }
        
        if parameters.hitCount >= parameters.requiredHits {
            #if DEBUG
            Logger.debug("\n=== ADC RETARGET (Cell Complete) ===")
            Logger.debug("Cell ID: \(cellID)")
            Logger.debug("Hit Count: \(parameters.hitCount)/\(parameters.requiredHits)")
            #endif
            return false
        }
        
        if parameters.cellID == cellID &&
            !parameters.isDestroyed &&
            parameters.hitCount < parameters.requiredHits {
            return true
        }
        
        #if DEBUG
        Logger.debug("\n=== ADC RETARGET (Target Invalid) ===")
        Logger.debug("Cell ID: \(cellID)")
        Logger.debug("Hit Count: \(parameters.hitCount)/\(parameters.requiredHits)")
        Logger.debug("Is Destroyed: \(parameters.isDestroyed)")
        #endif
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
            // First check the attachment point itself
            guard entity.isEnabled,
                  let attachComponent = entity.components[AttachmentPoint.self],
                  !attachComponent.isOccupied else {
                continue
            }
            
            // Find and validate the cancer cell
            guard let cancerCell = findParentCancerCell(for: entity, in: scene),
                cancerCell.isEnabled, // make sure it is enabled
                  let stateComponent = cancerCell.components[CancerCellStateComponent.self],
                  let cellID = stateComponent.parameters.cellID,
                  !stateComponent.parameters.isDestroyed else {
                continue
            }
            
            // Check hit count
            if stateComponent.parameters.hitCount >= stateComponent.parameters.requiredHits {
                continue
            }
            
            // NEW: Check the entire hierarchy is enabled
            var isHierarchyEnabled = true
            var current: Entity? = cancerCell
            while let parent = current?.parent {
                if !parent.isEnabled {
                    isHierarchyEnabled = false
                    break
                }
                current = parent
            }
            
            // Skip if any parent is disabled
            guard isHierarchyEnabled else {
                continue
            }

            let attachPosition = entity.position(relativeTo: nil)
            let cellCenter = cancerCell.position(relativeTo: nil)
            
            guard let score = Self.calculateAttachmentScore(
                attachPosition: attachPosition,
                cellCenter: cellCenter,
                approachPosition: currentPosition
            ) else { continue }
            
            #if DEBUG
            // Logger.debug("📊 Antigen Score - Distance: \(length(attachPosition - currentPosition)), Score: \(score)")
            #endif
            
            if score > bestScore {
                bestScore = score
                bestTarget = (entity, cellID)
                #if DEBUG
                Logger.debug("✨ New best target found - Score: \(score)")
                #endif
            }
        }
        
        #if DEBUG
        if bestTarget != nil {
            // Logger.debug("\n🎯 Selected target:")
            // Logger.debug("Cell ID: \(target.1)")
            // Logger.debug("Attachment Point: \(target.0.name)")
            // Logger.debug("Final Score: \(bestScore)")
        }
        #endif
        
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
