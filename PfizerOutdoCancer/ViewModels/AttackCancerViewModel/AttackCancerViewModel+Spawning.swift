import SwiftUI
import RealityKit
import RealityKitContent

extension AttackCancerViewModel {
    func spawnCancerCells(in root: Entity, from template: Entity, count: Int) async {
//        print("\n=== Starting Cancer Cell Spawning ===")
//        print("Target count: \(count)")
        
        // Create force entity with central gravity
        let forceEntity = createForceEntity()
        root.addChild(forceEntity)
        
        // Track front vs back spawns to ensure good distribution
        var frontSpawnCount = 0
        
        // Spawn cells sequentially
        for i in 0..<count {
            // Prefer front until we have enough there (50% in front)
            let preferFront = frontSpawnCount < Int(Double(count) * 0.5)
            
            // Spawn single cell
            if await spawnSingleCancerCell(in: root, from: template, index: i, preferFront: preferFront) != nil {
                // Track if this was a front spawn
                if preferFront {
                    frontSpawnCount += 1
                }
                
                // Small delay between spawns
                try? await Task.sleep(for: .seconds(0.2))
            }
        }
        
//        print("=== Finished Spawning ===")
//        print("Total parameters created: \(cellParameters.count)")
    }
    
    private func spawnSingleCancerCell(in root: Entity, from template: Entity, index: Int, preferFront: Bool) async -> Entity? {
//        print("\n=== Spawning Cancer Cell \(index) ===")
        
        let cell = template.clone(recursive: true)
        cell.name = "cancer_cell_\(index)"
        
        if let complexCell = cell.findEntity(named: "cancerCell_complex") {
            // Start with zero scale instead of zero opacity
            // complexCell.transform.scale = .init(repeating: 0)
            complexCell.opacity = 0
            
            // Setup all the physical aspects first
            configureCellPosition(complexCell, preferFront: preferFront)
            configureCellPhysics(complexCell)
            configureCellMovement(complexCell)
            setupCellIdentification(complexCell, cellID: index)
            
            // Create parameters on-demand
            // let parameters = CancerCellParameters(cellID: index)
//            print("Creating parameters for cell \(index)")
//            print("Required hits: \(parameters.requiredHits)")
            // cellParameters.append(parameters)
//            print("Total parameters after append: \(cellParameters.count)")
            
            // Add state component with reference to parameters
            // cell.components.set(CancerCellStateComponent(parameters: parameters))
//            print("Added CancerCellStateComponent with parameters")
            
            // Add ClosureComponent for state updates
            // cell.components.set(
            //     ClosureComponent { _ in
            //         guard let stateComponent = cell.components[CancerCellStateComponent.self],
            //               let cellID = stateComponent.parameters.cellID,
            //               cellID < self.cellParameters.count else { return }
                    
            //         // Get reference to the correct parameters instance
            //         let parameters = self.cellParameters[cellID]
                    
            //         // Update state
            //         parameters.hitCount = stateComponent.parameters.hitCount
            //         parameters.isDestroyed = stateComponent.parameters.isDestroyed
            //     }
            // )
//            print("Added ClosureComponent for state updates")
            
            root.addChild(cell)
            setupAttachmentPoints(for: cell, complexCell: complexCell, cellID: index)
            
            // Scale in with spring animation instead of fade
            // await complexCell.animateScale(from: 0, to: 1, duration: 0.5)
            // Fade in after setup
            await complexCell.fadeOpacity(to: 1.0, duration: 0.5)
//            print("✅ Successfully spawned cell \(index)")
            return cell
        } else {
            print("❌ Warning: Could not find cancerCell_complex entity")
            return nil
        }
    }
    
    private func createForceEntity() -> Entity {
        let forceEntity = Entity()
        // REF: Planet is positioned at [0, 0.5, -2] relative to device in reference project
        forceEntity.position = [0, 1.5, 0]  // Center point where we want gravity
        
        // REF: gravityMagnitude = 0.1 in reference Gravity.swift
        let gravityMagnitude: Float = 0.1
        // REF: minimumDistance = 0.2 in reference Gravity.swift
        let gravity = Gravity(gravityMagnitude: gravityMagnitude, minimumDistance: 0.2)
        // REF: mask = .all.subtracting(.actualEarthGravity) in reference Entity+Planet.swift
        let forceEffect = ForceEffect(
            effect: gravity,
            mask: .all.subtracting(.actualEarthGravity)  // Exactly like reference project
        )
        forceEntity.components.set(ForceEffectComponent(effects: [forceEffect]))
        return forceEntity
    }
    
    private func configureCellPosition(_ cell: Entity, preferFront: Bool) {
        // Generate random orbit parameters
        let radius = Float.random(in: 2.0...5.0)  // Increased radius range for more spread
        let height = Float.random(in: 0.0...3.5)  // Increased height range, starting from ground level
        
        // If preferring front, use angle range favoring right side (-30° to +60°)
        let theta: Float
        if preferFront {
            theta = Float.random(in: -Float.pi/6...Float.pi/3)  // -30° to +60°
        } else {
            // For back spawns, favor right side (120° to 270°)
            theta = Float.random(in: 2*Float.pi/3...3*Float.pi/2)
        }
        
        // Place cell on orbit
        // Note: Using negative cos for Z to spawn in front (-Z)
        cell.position = [
            sin(theta) * radius,  // X position on circle
            height,
            -cos(theta) * radius  // Z position on circle (negative for front)
        ]
    }
    
    private func configureCellPhysics(_ cell: Entity) {
        // First set of physics/collision components - Commented out as redundant
        // let shape = ShapeResource.generateSphere(radius: 0.32)  // Match cell size
        // let collisionComponent = CollisionComponent(
        //     shapes: [shape],
        //     filter: .init(group: .cancerCell, mask: .adc)
        // )
        // cell.components.set(collisionComponent)
        
        // var physicsBody = PhysicsBodyComponent(mode: .dynamic)
        // physicsBody.isAffectedByGravity = false
        // physicsBody.linearDamping = 0  // Higher damping to prevent too much movement
        // physicsBody.massProperties.mass = 1.0
        // cell.components[PhysicsBodyComponent.self] = physicsBody
        
        // REF: Planet uses radius = 0.12 or 0.25 in reference project
        let shape2 = ShapeResource.generateSphere(radius: 0.32)  // Cancer cell size
        let collisionComponent2 = CollisionComponent(
            shapes: [shape2],
            filter: .init(group: .cancerCell, mask: [.adc, .cancerCell])
        )
        cell.components.set(collisionComponent2)
        
        // REF: Planet uses mass = 1.0 in reference project
        var physicsBody2 = PhysicsBodyComponent(shapes: [shape2], mass: 1.0, mode: .dynamic)
        // REF: isAffectedByGravity = false in reference project (uses custom gravity)
        physicsBody2.isAffectedByGravity = false
        // REF: linearDamping = 0 in reference project
        physicsBody2.linearDamping = 0
        // REF: angularDamping = 0 in reference project
        physicsBody2.angularDamping = 0
        cell.components[PhysicsBodyComponent.self] = physicsBody2
        
        // Add PhysicsMotionComponent for impulse application
        cell.components.set(PhysicsMotionComponent())
    }
    
    private func configureCellMovement(_ cell: Entity) {
        // Calculate orbital parameters
        let radius = sqrt(cell.position.x * cell.position.x + cell.position.z * cell.position.z)
        let theta = atan2(cell.position.x, cell.position.z)
        
        // Calculate orbital velocity exactly like reference
        // REF: orbitSpeed = sqrt(gravityMagnitude / radius) in reference Entity+Planet.swift calculateVelocity()
        let gravityMagnitude: Float = 0.1
        let orbitSpeed = sqrt(gravityMagnitude / radius) * 0.5
        
        // REF: Direction calculation matches reference Entity+Planet.swift calculateVelocity()
        let orbitDirection = SIMD3<Float>(
            cos(theta),   // X component
            0,           // No vertical velocity
            -sin(theta)  // Z component
        )
        
        // REF: Angular velocity = [0, 1, 0] * 0.3 in reference Entity+Planet.swift
        let motionComponent = PhysicsMotionComponent(
            linearVelocity: orbitDirection * orbitSpeed,
            angularVelocity: [Float.random(in: -0...1), Float.random(in: -1...1), Float.random(in: -0...1)] * 1.0  // Add random tumbling
        )
        cell.components.set(motionComponent)
    }
    
    private func setupCellIdentification(_ cell: Entity, cellID: Int) {
        // Verify we have the marker component from RCP
        if cell.components.has(CancerCellComponent.self) {
            // Only add state component if it doesn't already exist
            if !cell.components.has(CancerCellStateComponent.self) {
                // Add our state component if not present
                let parameters = CancerCellParameters(cellID: cellID)
                let stateComponent = CancerCellStateComponent(parameters: parameters)
                cell.components.set(stateComponent)
            }
        }
    }
    
    private func setupAttachmentPoints(for cell: Entity, complexCell: Entity, cellID: Int) {
        if let scene = cell.scene {
            let attachPointQuery = EntityQuery(where: .has(AttachmentPoint.self))
            for entity in scene.performQuery(attachPointQuery) {
                // Check if this attachment point is part of our cell's hierarchy
                var current = entity.parent
                while let parent = current {
                    if parent == complexCell {
                        var attachPoint = entity.components[AttachmentPoint.self]!
                        attachPoint.cellID = cellID
                        entity.components[AttachmentPoint.self] = attachPoint
                        // print("Set cellID \(cellID) for attachment point \(entity.name)")
                        break
                    }
                    current = parent.parent
                }
            }
        }
    }
    
    func setupTutorialCancerCell(_ cell: Entity) {
        print("\n=== Setting up Tutorial Cancer Cell ===")
        
        if let complexCell = cell.findEntity(named: "cancerCell_complex") {
            // Setup all the physical aspects first (minus position and movement)
            configureCellPhysics(complexCell)
            
            // Create parameters before calling setupCellIdentification
            let parameters = CancerCellParameters(cellID: 0)
            parameters.isTutorialCell = true  // Mark as tutorial cell
            parameters.impactScale = CancerCellParameters.tutorialImpactScale  // Use reduced impact
            parameters.requiredHits = 10  // Set required hits for tutorial
            cellParameters.append(parameters)
//            print("Total parameters after append: \(cellParameters.count)")
            
            // Create and set state component with our parameters
            let stateComponent = CancerCellStateComponent(parameters: parameters)
            complexCell.components.set(stateComponent)
//            print("Added CancerCellStateComponent with parameters")
            
            // Now call setupCellIdentification which will skip creating new parameters
            // since the state component already exists
            // setupCellIdentification(complexCell, cellID: 0)

            // Add damping only for tutorial cell
            if var physicsBody = complexCell.components[PhysicsBodyComponent.self] {
                physicsBody.linearDamping = 0.8
                physicsBody.angularDamping = 0.5
                // Tutorial cell should be more responsive to impacts
                physicsBody.massProperties.mass = 0.1 // Lower mass = more responsive to impacts
                complexCell.components[PhysicsBodyComponent.self] = physicsBody
            }
            
            // Add ClosureComponent for state updates
            complexCell.components.set(
                ClosureComponent { [weak self] _ in
                    guard let stateComponent = complexCell.components[CancerCellStateComponent.self],
                          let cellID = stateComponent.parameters.cellID,
                          cellID < self?.cellParameters.count ?? 0 else { return }
                    
                    // Get reference to the correct parameters instance
                    let parameters = self?.cellParameters[cellID]
                    
                    // Update state
                    parameters?.hitCount = stateComponent.parameters.hitCount
                    parameters?.isDestroyed = stateComponent.parameters.isDestroyed
                }
            )
//            print("Added ClosureComponent for state updates")
            
            setupAttachmentPoints(for: cell, complexCell: complexCell, cellID: 0)
//            print("✅ Successfully configured tutorial cell")
        }
    }
}
