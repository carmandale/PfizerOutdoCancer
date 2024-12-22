import SwiftUI
import RealityKit
import RealityKitContent
import Combine

extension AttackCancerViewModel {
    // MARK: - Collision Setup
    func setupCollisions(in entity: Entity) {
        if let scene = entity.scene {
            let query = EntityQuery(where: .has(BloodVesselWallComponent.self))
            let objectsToModify = scene.performQuery(query)
            
            for object in objectsToModify {
                if var collision = object.components[CollisionComponent.self] {
                    collision.filter.group = .cancerCell
                    collision.filter.mask = .adc
                    object.components[CollisionComponent.self] = collision
                }
            }
        }
        setupCollisionSubscription()
    }
    
    // MARK: - Collision Subscription
    func setupCollisionSubscription() {
        guard let scene = scene else { return }
        
        // Store the AnyCancellable subscription
        subscription = scene.subscribe(to: CollisionEvents.Began.self) { [weak self] event in
            guard let self = self else { return }
            self.handleCollisionBegan(event)
        } as? EventSubscription
    }
    
    // MARK: - Collision Handling
    func handleCollisionBegan(_ event: CollisionEvents.Began) {
        guard shouldHandleCollision(event) else { return }
        
        // Check for head-microscope collision - only play sound, no transition
        if hasHeadCollision(event) && hasMicroscopeCollision(event) {
            print("Head collision with microscope detected")
            Task {
                await appModel.transitionToPhase(.building)
            }
            return
        }
        
        let entities = UnorderedPair(event.entityA, event.entityB)
        
        // Handle ADC-to-cell collisions
        if let adcComponent = entities.itemA.components[ADCComponent.self],
           let cellComponent = entities.itemB.components[CancerCellStateComponent.self] {
            handleADCToCellCollision(adc: entities.itemA, cell: entities.itemB)
        } else if let adcComponent = entities.itemB.components[ADCComponent.self],
                  let cellComponent = entities.itemA.components[CancerCellStateComponent.self] {
            handleADCToCellCollision(adc: entities.itemB, cell: entities.itemA)
        }
    }
    
    private func handleADCToCellCollision(adc: Entity, cell: Entity) {
        guard let stateComponent = cell.components[CancerCellStateComponent.self],
              let cellID = stateComponent.parameters.cellID,
              let parameters = cellParameters.first(where: { $0.cellID == cellID }) else {
            print("❌ Failed to handle collision - missing state component or parameters")
            return
        }
        
        print("💥 ADC hit cell \(cellID)")
        print("Current hit count: \(parameters.hitCount)")
        
        // Update parameters (source of truth)
        parameters.hitCount += 1
        parameters.wasJustHit = true
        
        print("New hit count: \(parameters.hitCount)")
        print("Required hits: \(parameters.requiredHits)")
        
        // Check if cell is destroyed
        if parameters.hitCount >= parameters.requiredHits {
            print("🎯 Cell \(cellID) destroyed!")
            parameters.isDestroyed = true
            // Let the CancerCellSystem handle the destruction effects
        }
        
        // Always remove the ADC
        adc.removeFromParent()
    }
    
    private func shouldHandleCollision(_ collision: CollisionEvents.Began) -> Bool {
        let entities = UnorderedPair(collision.entityA, collision.entityB)
        let currentTime = Date().timeIntervalSinceReferenceDate
        
        if let lastCollisionTime = debounce[entities] {
            if currentTime - lastCollisionTime < debounceThreshold {
                return false
            }
        }
        
        debounce[entities] = currentTime
        return true
    }
    
    private func hasHeadCollision(_ collision: CollisionEvents.Began) -> Bool {
        let entityA = collision.entityA
        let entityB = collision.entityB
        
        return entityA.name == "head" || entityB.name == "head"
    }
    
    private func hasMicroscopeCollision(_ collision: CollisionEvents.Began) -> Bool {
        let entityA = collision.entityA
        let entityB = collision.entityB
        
        let hasCollision = entityA.components[CollisionComponent.self]?.filter.group == .microscope ||
                          entityB.components[CollisionComponent.self]?.filter.group == .microscope
        
        return hasCollision
    }
}
