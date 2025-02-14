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
        
        print("=== Finished Spawning ===")
        print("Total parameters created: \(cellParameters.count)")
        print("Initial cellsDestroyed count: \(appModel.gameState.cellsDestroyed)")
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
            let parameters = CancerCellParameters(cellID: index)
            print("Creating parameters for cell \(index)")
            print("Required hits: \(parameters.requiredHits)")
            cellParameters.append(parameters)
            print("Total parameters after append: \(cellParameters.count)")
            
            // Add state component with reference to parameters
            cell.components.set(CancerCellStateComponent(parameters: parameters))
            print("Added CancerCellStateComponent with parameters")
            
            root.addChild(cell)
            setupAttachmentPoints(for: cell, complexCell: complexCell, cellID: index)

            // Fade in after setup
            await complexCell.fadeOpacity(to: 1.0, duration: 0.5)
           print("✅ Successfully spawned cell \(index)")
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
            filter: .init(group: .cancerCell, mask: .all ) // [.adc, .cancerCell]
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
        let baseSpeed = sqrt(gravityMagnitude / radius) * 0.5
        let minSpeed: Float = 0.15 // or whatever feels right
        let orbitSpeed = max(baseSpeed, minSpeed)
        
        // REF: Direction calculation matches reference Entity+Planet.swift calculateVelocity()
        let orbitDirection = SIMD3<Float>(
            cos(theta),   // X component
            0,            // No vertical velocity
            -sin(theta)   // Z component
        )
        
        // REF: Angular velocity = [0, 1, 0] * 0.3 in reference Entity+Planet.swift
        let rx = Float.random(in: -1...1)
        let ry = Float.random(in: -1...1)
        let rz = Float.random(in: -1...1)
        var spin = SIMD3<Float>(rx, ry, rz)

        // If length is tiny, normalize to some minimum spin
        let minSpinMagnitude: Float = 0.5
        let spinLength = simd_length(spin)
        if spinLength < 0.001 {
            // re-randomize or just pick a default axis
            spin = SIMD3<Float>(0,1,0)
        } else if spinLength < minSpinMagnitude {
            spin = normalize(spin) * minSpinMagnitude
        }

        let motionComponent = PhysicsMotionComponent(
            linearVelocity: orbitDirection * orbitSpeed,
            angularVelocity: spin
        )
        cell.components.set(motionComponent)
        
        // NEW: Store the base velocity for later speed adjustments in the speed boost system.
        cell.components.set(CancerCellMovementData(baseLinearVelocity: orbitDirection * orbitSpeed))
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
            // configureCellPhysics(complexCell)
            configureTestCellPhysics(complexCell)
            
            // Create parameters before calling setupCellIdentification
            let parameters = CancerCellParameters(cellID: 777)
            parameters.isTutorialCell = true  // Mark as tutorial cell
            parameters.physicsEnabled = false  // Disable physics for tutorial cell
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
            // complexCell.components.set(
            //     ClosureComponent { [weak self] _ in
            //         guard let self = self,
            //               let stateComponent = complexCell.components[CancerCellStateComponent.self],
            //               let cellID = stateComponent.parameters.cellID,
            //               cellID < self.cellParameters.count else { return }
                    
            //         // Directly update the corresponding parameters in the array.
            //         self.cellParameters[cellID].hitCount = stateComponent.parameters.hitCount
            //         self.cellParameters[cellID].isDestroyed = stateComponent.parameters.isDestroyed
            //     }
            // )
//            print("Added ClosureComponent for state updates")
            
            setupAttachmentPoints(for: cell, complexCell: complexCell, cellID: 777)
//            print("✅ Successfully configured tutorial cell")
        }
    }
    
    // Insert new test cell configuration functions above spawnTestFireCell

    private func configureTestCellPhysics(_ cell: Entity) {
        let shape = ShapeResource.generateSphere(radius: 0.32)  // Cancer cell size
        let collisionComponent = CollisionComponent(
            shapes: [shape],
            filter: .init(group: .cancerCell, mask: .all)
        )
        cell.components.set(collisionComponent)
        
        var physicsBody = PhysicsBodyComponent(shapes: [shape], mass: 0.1, mode: .dynamic)
        physicsBody.isAffectedByGravity = false
        physicsBody.linearDamping = 0.2
        physicsBody.angularDamping = 0.0
        cell.components[PhysicsBodyComponent.self] = physicsBody
        
        // Initialize motion component
        cell.components.set(PhysicsMotionComponent())
    }
    
    private func configureTestCellMovement(_ cell: Entity) {
        // Set linear velocity to zero to avoid orbiting
        let linearVelocity = SIMD3<Float>(0, 0, 0)
        
        // Calculate a random spin vector and reduce its intensity
        let rx = Float.random(in: -1...1)
        let ry = Float.random(in: -1...1)
        let rz = Float.random(in: -1...1)
        var spin = SIMD3<Float>(rx, ry, rz)
        let minSpinMagnitude: Float = 0.5
        let spinLength = simd_length(spin)
        if spinLength < 0.001 {
            spin = SIMD3<Float>(0, 1, 0)
        } else if spinLength < minSpinMagnitude {
            spin = normalize(spin) * minSpinMagnitude
        }
        // Scale spin to 60% for a visible, yet slowed, rotation
        spin *= 0.6
        
        let motionComponent = PhysicsMotionComponent(
            linearVelocity: linearVelocity,
            angularVelocity: spin
        )
        cell.components.set(motionComponent)
    }

    // Modify spawnTestFireCell to use the new test configuration functions
    func spawnTestFireCell(in root: Entity) async {
        do {
            // Instantiate the cancer cell template via assetLoadingManager
            let cancerCellTemplate = try await appModel.assetLoadingManager.instantiateAsset(
                withName: "cancer_cell",
                category: .cancerCell
            )
            
            // Clone the template for the test fire cell
            let cell = cancerCellTemplate.clone(recursive: true)
            cell.name = "cancer_cell_555"  // Mark the cell with ID 555

            let index = 555
            
            // Find the complex cell entity within our clone
            guard cell.findEntity(named: "cancerCell_complex") != nil else {
                print("❌ Test Fire: Could not find cancerCell_complex in test cell.")
                return
            }
            
            if let complexCell = cell.findEntity(named: "cancerCell_complex") {
                // Start with zero scale instead of zero opacity
                // complexCell.transform.scale = .init(repeating: 0)
                complexCell.opacity = 0
                
                // Setup all the physical aspects first
                complexCell.position = SIMD3<Float>(0, 1.0, -0.5)
                configureTestCellPhysics(complexCell)
                configureTestCellMovement(complexCell)
                setupCellIdentification(complexCell, cellID: index)
                
                // Create parameters on-demand
                let parameters = CancerCellParameters(cellID: index)
                parameters.isTutorialCell = true
                parameters.impactScale = CancerCellParameters.tutorialImpactScale
                parameters.requiredHits = 4
                cellParameters.append(parameters)
                print("Total parameters after append: \(cellParameters.count)")
                
                // Add state component with reference to parameters
                cell.components.set(CancerCellStateComponent(parameters: parameters))
                print("Added CancerCellStateComponent with parameters")
                
                root.addChild(cell)
                setupAttachmentPoints(for: cell, complexCell: complexCell, cellID: index)

                // Fade in after setup
                await complexCell.fadeOpacity(to: 1.0, duration: 0.5)
                print("✅ Successfully spawned cell \(index)")

                // set isTestFireActive to true
                appModel.gameState.isTestFireActive = true
                
                // Play the start button VO after cell is spawned
                
                print("⏱️ Wait for 10 seconds")
                try? await Task.sleep(for: .seconds(15))
                // await playStartButtonVO(in: root)
            } else {
                print("❌ Warning: Could not find cancerCell_complex entity")
            }

            
            
        } catch {
            print("❌ Test Fire: Failed to instantiate cancer cell template: \(error)")
        }
    }
}
