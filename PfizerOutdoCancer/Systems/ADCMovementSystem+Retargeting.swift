// ADCMovementSystem+Retargeting.swift

import RealityKit
import Foundation
import RealityKitContent

@MainActor
extension ADCMovementSystem {

    // MARK: - Constants
    private static let retargetDuration: Float = 0.5 // Duration for retargeting interpolation

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
        
        // Check if target entity still exists and is valid
        if targetEntity.parent == nil {
            print("\n=== ADC RETARGET (Target Lost) ===")
            print("Target attachment point has been removed from scene")
            return false
        }
        
        // Find parent cancer cell
        guard let cancerCell = findParentCancerCell(for: targetEntity, in: scene) else {
            print("\n=== ADC RETARGET (Cancer Cell Lost) ===")
            print("Parent cancer cell no longer exists")
            return false
        }
        
        // Check cancer cell state
        guard let stateComponent = cancerCell.components[CancerCellStateComponent.self],
              let cellID = adcComponent.targetCellID else {
            print("\n=== ADC RETARGET (Invalid State) ===")
            print("Missing state component or target cell ID")
            return false
        }
        
        // Validate using parameters
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
        
        // Check if this is still our target cell and it's valid
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

    func updateRetargetProgress(entity: Entity, context: SceneUpdateContext) {
        guard var adc = entity.components[ADCComponent.self],
              adc.needsRetarget,
              let newTarget = adc.newTargetPosition,
              let previousTarget = adc.previousTargetPosition
        else { return }
        
        // Calculate interpolation progress
        let deltaTime = Float(context.deltaTime)
        adc.targetInterpolationProgress = min(adc.targetInterpolationProgress + deltaTime / Float(ADCComponent.targetInterpolationDuration), 1.0)
        
        // Smooth step interpolation
        let t = adc.targetInterpolationProgress
        let smoothT = t * t * (3 - 2 * t)
        adc.targetWorldPosition = simd_mix(previousTarget, newTarget, SIMD3<Float>(repeating: smoothT))
        
        // Update movement parameters
        updatePathLength(adc: &adc)
        updateCurrentVelocity(entity: entity, adc: &adc, deltaTime: deltaTime)
        
        // Complete retarget
        if adc.targetInterpolationProgress >= 1.0 {
            finalizeRetarget(adc: &adc)
        }
        
        // Update component
        entity.components[ADCComponent.self] = adc
    }
    
    private func updatePathLength(adc: inout ADCComponent) {
        guard let start = adc.startWorldPosition,
              let target = adc.targetWorldPosition
        else { return }
        
        let newLength = distance(start, target)
        adc.previousPathLength = adc.pathLength
        adc.pathLength = newLength
        if adc.previousPathLength > Float.ulpOfOne {  // Prevent division by zero
            adc.traveledDistance *= newLength / adc.previousPathLength
        }
        adc.movementProgress = adc.traveledDistance / adc.pathLength
    }
    
    private func updateCurrentVelocity(entity: Entity, adc: inout ADCComponent, deltaTime: Float) {
        guard let targetPos = adc.targetWorldPosition else { return }
        
        let currentPos = entity.transform.translation
        let direction = normalize(targetPos - currentPos)
        adc.currentVelocity = direction * adc.speed
    }
    
    private func finalizeRetarget(adc: inout ADCComponent) {
        adc.previousTargetPosition = adc.targetWorldPosition
        adc.newTargetPosition = nil
        adc.needsRetarget = false
        adc.targetInterpolationProgress = 0
    }

}
