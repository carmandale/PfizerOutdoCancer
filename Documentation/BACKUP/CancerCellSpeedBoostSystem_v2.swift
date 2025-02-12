import RealityKit
import simd
import UIKit

@Observable
public class CancerCellSpeedBoostSystem: System {
    // MARK: - Configuration
    private struct BoostConfiguration {
        static let leftZoneThreshold: Float = 0.5      // X >= 0.5 = left side
        static let frontDistanceThreshold: Float = -1.5 // Z <= -1.5m (1.5m in front)
        static let maxBoostMultiplier: Float = 4.0
        static let accelerationLerp: Float = 2.5
        static let decelerationLerp: Float = 0.8
    }
    
    // MARK: - System Setup
    private static let query = EntityQuery(where: 
        .has(CancerCellMovementData.self) && 
        .has(PhysicsMotionComponent.self)
    )
    
    private var originalMaterials = [Entity.ID: [Material]]()
    private let debugVisualization: ModelEntity?
    
    public required init(scene: Scene) {
        // Debug visualization setup
        debugVisualization = ModelEntity(
            mesh: .generateBox(
                size: SIMD3<Float>(1.0, 0.01, 1.0),
                cornerRadius: 0.05
            ),
            materials: [UnlitMaterial(
                color: .systemOrange.withAlphaComponent(0.3),
                opacity: 0.3
            )]
        )
        
        if let debugViz = debugVisualization {
            debugViz.position = SIMD3<Float>(
                BoostConfiguration.leftZoneThreshold + 0.5,
                0,
                BoostConfiguration.frontDistanceThreshold - 0.5
            )
            scene.addAnchor(Entity().addChild(debugViz))
        }
    }
    
    // MARK: - Update Loop
    public func update(context: SceneUpdateContext) {
        let deltaTime = Float(context.deltaTime)
        
        for entity in context.scene.performQuery(Self.query) {
            guard var motion = entity.components[PhysicsMotionComponent.self],
                  let movementData = entity.components[CancerCellMovementData.self] else { continue }
            
            let cellPos = entity.position(relativeTo: nil)
            
            // Calculate boost zone status
            let isInBoostZone = cellPos.x >= BoostConfiguration.leftZoneThreshold && 
                              cellPos.z <= BoostConfiguration.frontDistanceThreshold
            
            // Calculate progressive boost intensity
            let xNormalized = (cellPos.x - BoostConfiguration.leftZoneThreshold) / 0.5
            let zNormalized = abs(cellPos.z - BoostConfiguration.frontDistanceThreshold) / 1.0
            let intensity = min(xNormalized * zNormalized, 1.0)
            
            let targetMultiplier = isInBoostZone ? 
                1.0 + (BoostConfiguration.maxBoostMultiplier - 1.0) * intensity : 
                1.0
                
            // Select interpolation speed
            let lerpFactor = targetMultiplier > 1.0 ? 
                BoostConfiguration.accelerationLerp : 
                BoostConfiguration.decelerationLerp
                
            // Apply smooth velocity transition
            let baseVelocity = movementData.baseLinearVelocity
            let desiredVelocity = simd_normalize(baseVelocity) * 
                (simd_length(baseVelocity) * targetMultiplier)
            
            motion.linearVelocity = simd_mix(
                motion.linearVelocity,
                desiredVelocity,
                SIMD3<Float>(repeating: lerpFactor * deltaTime)
            )
            
            entity.components.set(motion)
            
            // Visual feedback system
            self.updateMaterialFeedback(for: entity, isActive: isInBoostZone)
        }
    }
    
    // MARK: - Material Management
    private func updateMaterialFeedback(for entity: Entity, isActive: Bool) {
        guard var modelComponent = entity.components[ModelComponent.self] else { return }
        
        if isActive {
            if originalMaterials[entity.id] == nil {
                originalMaterials[entity.id] = modelComponent.materials
            }
            
            let boostMaterial = UnlitMaterial(
                color: .systemOrange,
                opacity: 0.8,
                emissiveColor: .systemOrange,
                emissiveIntensity: 0.5
            )
            modelComponent.materials = [boostMaterial]
        } else {
            if let original = originalMaterials[entity.id] {
                modelComponent.materials = original
                originalMaterials.removeValue(forKey: entity.id)
            }
        }
        
        entity.components.set(modelComponent)
    }
}