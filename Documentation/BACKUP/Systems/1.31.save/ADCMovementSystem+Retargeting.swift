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
        guard let (newTarget, newCellID) = findNewTarget(for: entity, currentPosition: currentPosition, in: scene) else {
            print("⚠️ No valid targets found for retargeting")
            return false
        }
        
        print("🎯 Retargeting ADC to new cancer cell (ID: \(newCellID))")
        
        // Skip if targeting same cell
        if adcComponent.targetCellID == newCellID {
            print("⚠️ Attempting to retarget to same cell - skipping")
            return false
        }
        
        // Set up target interpolation
        if let currentTargetID = adcComponent.targetEntityID,
           let currentTarget = scene.findEntity(id: currentTargetID) {
            adcComponent.previousTargetPosition = currentTarget.position(relativeTo: nil)
            adcComponent.newTargetPosition = newTarget.position(relativeTo: nil)
            adcComponent.targetInterpolationProgress = 0
        }
        
        // Update component with new target
        adcComponent.targetEntityID = newTarget.id
        adcComponent.targetCellID = newCellID
        
        // Mark the attachment point as occupied
        if var attachPoint = newTarget.components[AttachmentPoint.self] {
            attachPoint.isOccupied = true
            newTarget.components[AttachmentPoint.self] = attachPoint
            print("✅ Marked attachment point as occupied")
        }
        
        return true
    }

    static func validateTarget(_ targetEntity: Entity, _ adcComponent: ADCComponent, in scene: Scene) -> Bool {
        // If this is headPosition, it's always valid
        if targetEntity.components[PositioningComponent.self] != nil {
            return true
        }
        
        // Skip logging for routine validation checks
        let isInitialValidation = targetEntity.components[AttachmentPoint.self]?.isOccupied == false
        
        if isInitialValidation {
            print("\n=== Validating Target ===")
            print("Target Entity: \(targetEntity.name)")
            print("ADC Component Target Cell ID: \(String(describing: adcComponent.targetCellID))")
        }
        
        // Check if target entity still exists and is valid
        if targetEntity.parent == nil {
            print("⚠️ Target attachment point has been removed from scene")
            return false
        }
        
        // Find parent cancer cell
        guard let cancerCell = findParentCancerCell(for: targetEntity, in: scene) else {
            print("⚠️ Parent cancer cell no longer exists")
            return false
        }
        
        // Check cancer cell state using new component structure
        guard let stateComponent = cancerCell.components[CancerCellStateComponent.self],
              let cellID = adcComponent.targetCellID else {
            print("⚠️ Missing state component or target cell ID")
            return false
        }
        
        // Validate using parameters
        let parameters = stateComponent.parameters
        
        // Only log state changes
//        if parameters.hitCount > 0 {
//            print("📊 Cell \(cellID): \(parameters.hitCount)/\(parameters.requiredHits) hits")
//        }
        
        // Check if this is still our target cell and it's valid
        if parameters.cellID == cellID &&
           !parameters.isDestroyed &&
           parameters.hitCount < parameters.requiredHits {
            return true
        }
        
        print("❌ Target validation failed")
        return false
    }
    
    static func findNewTarget(for adcEntity: Entity, currentPosition: SIMD3<Float>, in scene: Scene) -> (Entity, Int)? {
        print("\n=== Finding New Target ===")
        let query = EntityQuery(where: .has(AttachmentPoint.self))
        var closestDistance: Float = Float.infinity
        var bestTarget: (attachPoint: Entity, cellID: Int)? = nil
        
        let entities = scene.performQuery(query)
        
        for entity in entities {
            // First check if attachment point is available
            guard let attachComponent = entity.components[AttachmentPoint.self],
                  !attachComponent.isOccupied else {
                continue
            }
            
            // Find and validate parent cancer cell
            guard let cancerCell = findParentCancerCell(for: entity, in: scene),
                  let stateComponent = cancerCell.components[CancerCellStateComponent.self],
                  let cellID = stateComponent.parameters.cellID,
                  !stateComponent.parameters.isDestroyed else {
                continue
            }
            
            // Skip if cell has reached required hits
            if stateComponent.parameters.hitCount >= stateComponent.parameters.requiredHits {
                continue
            }
            
            // Calculate distance
            let attachPosition = entity.position(relativeTo: nil)
            let distance = length(attachPosition - currentPosition)
            
            // Skip if the target is too close (prevent sharp turns)
            if distance < 0.3 {  // Minimum distance threshold
                continue
            }
            
            if distance < closestDistance {
                closestDistance = distance
                bestTarget = (attachPoint: entity, cellID: cellID)
                print("✨ New best target found - Distance: \(distance)")
            }
        }
        
        if let target = bestTarget {
            print("\n🎯 Selected target:")
            print("Cell ID: \(target.cellID)")
            print("Attachment Point: \(target.attachPoint.name)")
            print("Distance: \(closestDistance)")
        }
        
        return bestTarget
    }
    
    private static func findAttachmentPoints(in entity: Entity) -> [Entity] {
        var points: [Entity] = []
        
        // Check if this entity has an attachment point
        if entity.components[AttachmentPoint.self] != nil {
            points.append(entity)
        }
        
        // Recursively check children
        for child in entity.children {
            points.append(contentsOf: findAttachmentPoints(in: child))
        }
        
        return points
    }
}
