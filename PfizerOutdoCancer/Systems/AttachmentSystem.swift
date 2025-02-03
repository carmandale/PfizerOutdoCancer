import Foundation
@preconcurrency import RealityKit
import RealityKitContent
import SwiftUI

public struct AttachmentSystem: System {
    // Queries as instance properties to avoid concurrency issues
    let attachmentQuery = EntityQuery(where: .has(AttachmentPoint.self))
    let cancerCellQuery = EntityQuery(where: .has(CancerCellStateComponent.self))

    public init(scene: RealityKit.Scene) { }
    
    @MainActor
    public func update(context: SceneUpdateContext) {
        for _ in context.entities(matching: attachmentQuery, updatingSystemWhen: .rendering) {
            // if you find attachments, and they have marked themselves as occupied, then increment the hitCount of that attachments parent cancer cell. only one increment per isOccupied
            // if entity.components[AttachmentPoint.self]?.isOccupied == true {
            //     if let cellEntity = entity.parent,
            //        var stateComponent = cellEntity.components[CancerCellStateComponent.self] {
            //         stateComponent.parameters.hitCount += 1
            //         cellEntity.components[CancerCellStateComponent.self] = stateComponent
            //     }
            // }
        }
    }
    
    // MARK: - Public API
    
    @MainActor
    public static func getAvailablePoint(
        in scene: RealityKit.Scene,
        forCellID cellID: Int,
        approachPosition: SIMD3<Float>? = nil
    ) -> Entity? {
        let query = EntityQuery(where: .has(AttachmentPoint.self))
        let entities = scene.performQuery(query)
        
        // If no approach position provided, use simple first-available logic
        if approachPosition == nil {
            return entities.first { entity in
                guard let attachPoint = entity.components[AttachmentPoint.self] else { return false }
                return attachPoint.cellID == cellID && !attachPoint.isOccupied
            }
        }
        
        // Otherwise use scoring logic to find best available point
        var bestScore: Float = -Float.infinity
        var bestPoint: Entity? = nil
        
        for entity in entities {
            guard let attachPoint = entity.components[AttachmentPoint.self],
                  attachPoint.cellID == cellID && !attachPoint.isOccupied else {
                continue
            }
            
            // Find parent cancer cell for center position
            var current = entity
            var cellCenter: SIMD3<Float>? = nil
            while let parent = current.parent {
                if parent.components[CancerCellStateComponent.self] != nil {
                    cellCenter = parent.position(relativeTo: nil)
                    break
                }
                current = parent
            }
            
            guard let cellCenter = cellCenter else { continue }
            
            let attachPosition = entity.position(relativeTo: nil)
            
            guard let score = ADCMovementSystem.calculateAttachmentScore(
                attachPosition: attachPosition,
                cellCenter: cellCenter,
                approachPosition: approachPosition!
            ) else { continue }
            
            print("📊 Attachment Point Score - Point: \(entity.name), Score: \(score)")
            
            if score > bestScore {
                bestScore = score
                bestPoint = entity
                print("✨ New best attachment point - Score: \(score)")
            }
        }
        
        if let bestPoint = bestPoint {
            print("🎯 Selected attachment point: \(bestPoint.name) with score: \(bestScore)")
        }
        
        return bestPoint
    }
    
    @MainActor
    public static func markPointAsOccupied(_ point: Entity) {
        guard var attachPoint = point.components[AttachmentPoint.self] else {
            print("No AttachmentPoint component found")
            return
        }
        
        attachPoint.isOccupied = true
        point.components[AttachmentPoint.self] = attachPoint
    }
    
    @MainActor
    public static func markPointAsAvailable(_ entity: Entity) {
        guard var attachPoint = entity.components[AttachmentPoint.self] else { return }
        attachPoint.isOccupied = false
        entity.components[AttachmentPoint.self] = attachPoint
    }
}
