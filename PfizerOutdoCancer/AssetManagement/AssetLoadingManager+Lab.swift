import Foundation
import RealityKit
import RealityKitContent

extension AssetLoadingManager {


    
    internal func loadLabEquipmentAssets(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
        let labAssets = [
            "autoclave", "beaker", "beaker_tall", "bin", "bottle_liquid",
            "bottle_pill", "bottle_square", "bottle_squat", "centrifuge",
            "chair", "deskShelf_double", "deskShelf_single", 
            "dryingRack", "flask_conical", "flask_conical_lg",
            "flask_flatBottom", "flask_flatBottom_lg", "flask_volumetric",
            "flask_volumetric_lg", "fridge_sm", "glovesBox_A", "glovesBox_B",
            "jar_pill", "jar_pill_sm", "laptop", "mettlerBalance",
            "mettlerBalance_box", "microscope", "oven", "pcKeyboard",
            "pcMonitor", "pcMouse", "pcTower", "shaker", "squirter",
            "stool", "testTubes_lg_set", "testTubes_sm_set", "tester",
            "uvBox", "vortex", "wasteBasket"
        ]
        
        for assetName in labAssets {
            group.addTask {
                let fullPath = "\(self.labObjectsPath)/\(assetName)"
                print("Starting to load asset: \(fullPath)")
                do {
                    let entity = try await Entity(named: fullPath, in: realityKitContentBundle)
                    print("Successfully loaded asset: \(fullPath)")
                    return .success(entity: entity, key: fullPath, category: .labEquipment)
                } catch {
                    print("Failed to load asset: \(fullPath), error: \(error)")
                    return .failure(key: fullPath, category: .labEquipment, error: error)
                }
            }
            taskCount += 1
        }
    }
    
    /// Load and populate a complete lab scene
    func loadPopulatedLabScene() async throws -> Entity {
        // Load the empty lab scene
        let emptyScene = try await Entity(named: "\(labObjectsPath)/lab_empties", in: realityKitContentBundle)
        
        // Find all empty transforms and get the total count
        let (emptyTransforms, totalCount) = findEmptyTransforms(in: emptyScene)
        var loadedCount = 0
        
        // Process each empty transform
        for empty in emptyTransforms {
            if let assetName = extractAssetName(from: empty.name) {
                // Load or get cached asset
                let asset = try await loadLabAsset(named: assetName)
                
                // Clone and parent
                let instance = asset.clone(recursive: true)
                empty.addChild(instance)
                
                // Configure the instance
                configureLabInstance(instance, for: empty)

                // Update progress
                loadedCount += 1
                let progress = Float(loadedCount) / Float(totalCount)
                loadingState = .loading(progress: progress)
            }
        }
        
        // Apply final scene rotation
        await MainActor.run {
            emptyScene.orientation = simd_quatf(angle: -.pi/2, axis: [1, 0, 0])
        }
        
        return emptyScene
    }
    
    private func loadLabAsset(named assetName: String) async throws -> Entity {
        return try await self.loadEntity(named: "\(labObjectsPath)/\(assetName)")
    }
    
    // MARK: - Private Helper Methods
    
    private func findEmptyTransforms(in scene: Entity) -> ([Entity], Int) {
        var empties: [Entity] = []
        
        func traverse(entity: Entity) {
            if entity.name.hasPrefix("empty_") {
                empties.append(entity)
            }
            
            for child in entity.children {
                traverse(entity: child)
            }
        }
        
        traverse(entity: scene)
        return (empties, empties.count) // Return both the array and the count
    }
    
    private func extractAssetName(from name: String) -> String? {
        // Remove the prefix "empty_" and the suffix "_<number>"
        let prefix = "empty_"
        guard name.hasPrefix(prefix) else { return nil }
        let nameWithoutPrefix = String(name.dropFirst(prefix.count))
        
        // Find the last underscore which precedes the number
        if let lastUnderscoreIndex = nameWithoutPrefix.lastIndex(of: "_") {
            let assetName = nameWithoutPrefix[..<lastUnderscoreIndex]
            return String(assetName)
        } else {
            // If there's no underscore, return the entire name
            return nameWithoutPrefix
        }
    }
    
    private func configureLabInstance(_ instance: Entity, for empty: Entity) {
        instance.position = .zero
        instance.orientation = .init()
        instance.scale = .one
    }
    
    /// Loads and assembles the complete lab environment on demand
    func loadAssembledLab() async throws -> Entity {
        print("📱 Starting lab environment assembly")
        
        // Check if we already have it cached
        if let cached = entityTemplates["assembled_lab"] {
            print("✅ Using cached assembled lab")
            return cached.clone(recursive: true)
        }
        loadingState = .loading(progress: 0.0)

        let assetRoot = Entity()
        
        // Use existing assembly logic
        let labEnvironmentScene = try await loadEntity(named: "LabEnvironment")
        assetRoot.addChild(labEnvironmentScene)
        
        // Use existing equipment population
        let equipmentScene = try await loadPopulatedLabScene()
        assetRoot.addChild(equipmentScene)
        
        // Use existing IBL setup
        try await IBLUtility
            .addImageBasedLighting(
                to: assetRoot,
                imageName: "lab_v005",
                intensity: 1.0
            )
        
        // Cache the assembled lab
        entityTemplates["assembled_lab"] = assetRoot
        print("✅ Completed lab environment assembly")
        return assetRoot.clone(recursive: true)
    }
} 
