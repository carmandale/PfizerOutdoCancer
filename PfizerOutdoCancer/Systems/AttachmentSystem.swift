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
    public static func getAvailablePoint(in scene: RealityKit.Scene, forCellID cellID: Int) -> Entity? {
        let query = EntityQuery(where: .has(AttachmentPoint.self))
        let entities = scene.performQuery(query)
        
        // Find first unoccupied attachment point for this cell
        return entities.first { entity in
            guard let attachPoint = entity.components[AttachmentPoint.self] else { return false }
            return attachPoint.cellID == cellID && !attachPoint.isOccupied
        }
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
