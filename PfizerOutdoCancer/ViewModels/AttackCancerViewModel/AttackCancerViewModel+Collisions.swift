import SwiftUI
import RealityKit
import RealityKitContent
import Combine

extension AttackCancerViewModel {
    // MARK: - Collision Setup
    func setupCollisions(in entity: Entity) {
        // Cancel any existing subscription first
        subscription?.cancel()
        subscription = nil
        
        if let scene = entity.scene {
            let query = EntityQuery(where: .has(BloodVesselWallComponent.self))
            let objectsToModify = scene.performQuery(query)
            
            for object in objectsToModify {
                if var collision = object.components[CollisionComponent.self] {
                    collision.filter.group = .cancerCell
                    collision.filter.mask = .cancerCell
                    object.components[CollisionComponent.self] = collision
                }
            }
            setupCollisionSubscription()
        }
    }
    
    // MARK: - Collision Subscription
    func setupCollisionSubscription() {
        guard let scene = scene else { return }
        
        // Store the SceneEventSubscription
        subscription = scene.subscribe(to: CollisionEvents.Began.self) { [weak self] event in
            guard let self = self else { return }
            self.handleCollisionBegan(event)
        }
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
        // if let _ = entities.itemA.components[ADCComponent.self],
        //    let _ = entities.itemB.components[CancerCellStateComponent.self] {
        //     handleADCToCellCollision(adc: entities.itemA, cell: entities.itemB, collision: event)
        // } else if let _ = entities.itemB.components[ADCComponent.self],
        //           let _ = entities.itemA.components[CancerCellStateComponent.self] {
        //     handleADCToCellCollision(adc: entities.itemB, cell: entities.itemA, collision: event)
        // }
    }
    
    private func handleADCToCellCollision(adc: Entity, cell: Entity, collision: CollisionEvents.Began) {
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
        
        // Apply scaled physics impact if enabled
        if parameters.physicsEnabled {
            // Scale the collision impulse based on the cell's impact scale, then reduce to 10%
            let scaledImpulse = collision.impulse * parameters.impactScale * 0.1
            
            // Store impact values in parameters for reference (logging, analytics, etc.)
            parameters.linearVelocity = collision.impulseDirection * scaledImpulse
            
            // Calculate angular velocity based on impulse
            let randomRotation = SIMD3<Float>(
                Float.random(in: -1...1),
                Float.random(in: -1...1),
                Float.random(in: -1...1)
            )
            parameters.angularVelocity = normalize(randomRotation) * (scaledImpulse * 2.0)
            
            // NEW: actually apply the impulse to the cell's PhysicsMotionComponent
            var motion = cell.components[PhysicsMotionComponent.self] ?? PhysicsMotionComponent()
            motion.linearVelocity += collision.impulseDirection * scaledImpulse
            motion.angularVelocity += normalize(randomRotation) * (scaledImpulse * 2.0)
            cell.components.set(motion)
            
            if parameters.isTutorialCell {
                print("Tutorial cell impact - using scale: \(parameters.impactScale), impulse: \(scaledImpulse)")
            }
        }
        
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
