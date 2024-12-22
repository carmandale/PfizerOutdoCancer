
import Foundation
@preconcurrency import RealityKit
import OSLog

struct ADCProximityComponent: Component, Codable {
    let minScale: Float
    let maxScale: Float
    let minProximity: Float
    let maxProximity: Float
}

struct ADCProximitySourceComponent: Component, Codable {
}


final class ADCProximitySystem: System {
    
    static let proxymityQuery = EntityQuery(where: .has(ADCProximityComponent.self))
    static let proxymitySourceQuery = EntityQuery(where: .has(ADCProximitySourceComponent.self))
    
//    static let log = OSLog(subsystem: "com.groove.Pfizer", category: "ProximityComponent")
    
    public init(scene: RealityKit.Scene) {
        ADCProximityComponent.registerComponent()
        ADCProximitySourceComponent.registerComponent()
    }
    
    public func update(context: SceneUpdateContext) {
        let sourceEntities = context.entities(matching: Self.proxymitySourceQuery, updatingSystemWhen: .rendering).map({ $0 })
        let proximityEntities = context.entities(matching: Self.proxymityQuery, updatingSystemWhen: .rendering).map({ $0 })
        
//        os_log(.debug, "ITR..ProximitySystem(): sourceCount: \(sourceEntities.count), proximityCount: \(proximityEntities.count)")
        guard let sourceEntity = sourceEntities.first,
              !proximityEntities.isEmpty else {
            return
        }
             
        

        let sourcePosition = sourceEntity.position(relativeTo: nil)
//        let sourceOrientation = sourceEntity.orientation(relativeTo: nil)
        
        for targetEntity in proximityEntities{
            let targetPosition = targetEntity.position(relativeTo: nil)
            let dist = distance(sourcePosition, targetPosition)
            guard let proximity = targetEntity.components[ADCProximityComponent.self] else { continue }
            
//            os_log(.debug, "ITR..Proximity: \(dist)")
            
            // Scale interpolation
            var newScale: Float = dist * (proximity.maxScale - proximity.minScale) / (proximity.maxProximity - proximity.minProximity) + proximity.minScale
            newScale = max(proximity.minScale, min(newScale, proximity.maxScale))
            targetEntity.scale = .init(x: newScale, y: newScale, z: newScale)

//            // Rotation interpolation
//            if dist < proximity.minProximity {
//                targetEntity.orientation = sourceOrientation
//            } else if dist > proximity.maxProximity {
//                targetEntity.orientation = simd_quatf()
//            } else {
//                let t = max(0.0, min(1.0, 1.0 - (dist - proximity.minProximity) / (proximity.maxProximity - proximity.minProximity)))
//                let interpolatedOrientation = simd_slerp(targetEntity.orientation(relativeTo: nil), sourceOrientation, t)
//                targetEntity.orientation = interpolatedOrientation
//            }
        }
    }
}
