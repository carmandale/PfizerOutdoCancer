//
//  AssetLoadingManager.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman
//

import Foundation
import RealityKit
import RealityKitContent

/// Represents the result of loading an asset
enum LoadResult {
    case success(entity: Entity, key: String, category: AssetCategory)
    case failure(key: String, category: AssetCategory, error: Error)
}

/// Structure to track failed asset loads
struct FailedAsset {
    let key: String
    let category: AssetCategory
    let error: Error
}

/// Categories of assets for each environment
enum AssetCategory {
    case introEnvironment
    case outroEnvironment
    case labEnvironment
    case labEquipment
    case buildADCEnvironment
    case attackCancerEnvironment
    case cancerCell
    case adc
}

/// Loading state of the asset manager
enum LoadingState {
    case notStarted
    case loading(progress: Float)
    case completed
    case error(Error)
}

/// Add at the top level, before the AssetLoadingManager class
enum AssetError: Error {
    case resourceNotFound
    case criticalAssetsMissing(String)
    case materialNotFound
    case protobufError(String)  // Add protobuf error case
    // Add other asset-related errors as needed
}

/// Manages the loading and instantiation of assets in the lab environment
@MainActor
final class AssetLoadingManager {
    // MARK: - Properties
    
    /// Singleton instance
    static let shared = AssetLoadingManager()
    
    /// Cached entity templates for efficient cloning
    internal var entityTemplates: [String: Entity] = [:]
    
    /// Track audio controllers for proper cleanup
    private var audioControllers: [Entity.ID: AudioPlaybackController] = [:]
    
    /// Track failed asset loads
    private var failedAssets: [FailedAsset] = []
    
    /// Public accessor for failed assets
    var loadingFailures: [FailedAsset] { failedAssets }
    
    /// Path to lab objects in RealityKitContent bundle
    internal let labObjectsPath = "Assets/Lab/Objects"
    
    /// Current loading state
    private var loadingState: LoadingState = .notStarted
    
    /// The current state of asset loading
    var state: LoadingState { loadingState }
    
    // MARK: - Public Methods
    
    /// Releases intro environment assets asynchronously
    func releaseIntroEnvironment() async {
        print("\n=== Starting Intro Environment Cleanup ===")
        
        // Log initial state
        print("📊 Current template cache size: \(entityTemplates.count) entities")
        print("📊 Current templates: \(entityTemplates.keys.joined(separator: ", "))")
        
        // Remove from entity templates
        let keysToRemove = [
            "intro_environment",
            "intro_warp",
        ]
        
        print("🗑️ Preparing to remove \(keysToRemove.count) intro assets:")
        for key in keysToRemove {
            if let entity = entityTemplates[key] {
                print("\n🗑️ Removing asset: \(key)")
                // Use releaseEntity for thorough cleanup including audio
                releaseEntity(entity)
                // Remove from templates after release
                entityTemplates.removeValue(forKey: key)
                print("✅ Released asset: \(key)")
            } else {
                print("⚠️ Asset not found in cache: \(key)")
            }
        }
        
        // Log final state
        print("\n📊 Updated template cache size: \(entityTemplates.count) entities")
        if let remainingKeys = entityTemplates.keys.first {
            print("🔒 Remaining asset: \(remainingKeys)")
        }
        print("✅ Completed intro environment cleanup\n")
    }
    
    /// Releases an entity and all its resources
    func releaseEntity(_ entity: Entity) {
        // 1. Log the hierarchy before removal for debugging
        print("\n📝 Releasing entity: \(entity.name)")
        print("  - Child count: \(entity.children.count)")
        print("  - Has components: \(entity.components.isEmpty ? "no" : "yes")")
        
        // 2. Recursively release all children first
        for child in entity.children {
            releaseEntity(child)
        }
        
        // 3. Stop any active audio playback
        if let controller = audioControllers[entity.id] {
            print("  - Stopping audio playback for entity: \(entity.name)")
            controller.stop()
            audioControllers.removeValue(forKey: entity.id)
        }
        
        // 4. Remove all components
        entity.components.removeAll()
        
        // 5. Remove from parent
        if let parent = entity.parent {
            print("  - Detaching from parent: \(parent.name)")
            entity.removeFromParent()
        }
        
        print("✅ Released entity: \(entity.name)\n")
    }
    
    /// Releases lab environment assets asynchronously
    func releaseLabEnvironment() async {
        print("\n=== Starting Lab Environment Cleanup ===")
        
        // Log initial state
        print("📊 Current template cache size: \(entityTemplates.count) entities")
        
        // Get all keys except assembled_lab
        let keysToRemove = entityTemplates.keys.filter { $0 != "assembled_lab" }
        
        print("🗑️ Preparing to remove \(keysToRemove.count) assets after lab phase:")
        for key in keysToRemove {
            if let entity = entityTemplates[key] {
                print("\n🗑️ Removing asset: \(key)")
                // Use new releaseEntity function for thorough cleanup
                releaseEntity(entity)
                // Remove from templates after release
                entityTemplates.removeValue(forKey: key)
                print("✅ Released asset: \(key)")
            }
        }
        
        // Log final state
        print("\n📊 Updated template cache size: \(entityTemplates.count) entities")
        if let remainingKeys = entityTemplates.keys.first {
            print("🔒 Remaining asset: \(remainingKeys)")
        }
        print("✅ Completed aggressive lab cleanup\n")
    }
    
    /// Releases outro environment assets asynchronously
    func releaseOutroEnvironment() async {
        print("\n=== Starting Outro Environment Cleanup ===")
        
        // Log initial state
        print("📊 Current template cache size: \(entityTemplates.count) entities")
        print("📊 Current templates: \(entityTemplates.keys.joined(separator: ", "))")
        
        // Remove from entity templates
        let keysToRemove = [
            "outro_environment"
        ]
        
        print("🗑️ Preparing to remove \(keysToRemove.count) outro assets:")
        for key in keysToRemove {
            if let entity = entityTemplates[key] {
                print("\n🗑️ Removing asset: \(key)")
                // Use releaseEntity for thorough cleanup including audio
                releaseEntity(entity)
                // Remove from templates after release
                entityTemplates.removeValue(forKey: key)
                print("✅ Released asset: \(key)")
            } else {
                print("⚠️ Asset not found in cache: \(key)")
            }
        }
        
        // Log final state
        print("\n📊 Updated template cache size: \(entityTemplates.count) entities")
        if let remainingKeys = entityTemplates.keys.first {
            print("🔒 Remaining asset: \(remainingKeys)")
        }
        print("✅ Completed outro environment cleanup\n")
    }
    
    /// Releases attack cancer environment assets asynchronously
    func releaseAttackCancerEnvironment() async {
        print("\n=== Starting Attack Cancer Environment Cleanup ===")
        
        // Log initial state
        print("📊 Current template cache size: \(entityTemplates.count) entities")
        print("📊 Current templates: \(entityTemplates.keys.joined(separator: ", "))")
        
        // Remove voice-over assets
        let keysToRemove = [
            "game_start_vo"
        ]
        
        print("🗑️ Preparing to remove \(keysToRemove.count) attack cancer VO assets:")
        for key in keysToRemove {
            if let entity = entityTemplates[key] {
                print("\n🗑️ Removing asset: \(key)")
                releaseEntity(entity)
                entityTemplates.removeValue(forKey: key)
                print("✅ Released asset: \(key)")
            } else {
                print("⚠️ Asset not found in cache: \(key)")
            }
        }
        
        // Log final state
        print("\n📊 Updated template cache size: \(entityTemplates.count) entities")
        if let remainingKeys = entityTemplates.keys.first {
            print("🔒 Remaining asset: \(remainingKeys)")
        }
        print("✅ Completed attack cancer environment cleanup\n")
    }
    
    /// Get the current loading progress
    func loadingProgress() -> Float {
        switch loadingState {
        case .notStarted:
            return 0
        case .loading(let progress):
            return progress
        case .completed:
            return 1
        case .error:
            return 0
        }
    }
    
    /// Logs the entity hierarchy during instantiation
    func instantiateEntity(_ key: String) async -> Entity? {
        guard let template = entityTemplates[key] else {
            print("Warning: No template found for key: \(key)")
            return nil
        }
        let clone = template.clone(recursive: true)
        print("\nCloned entity for key: \(key)")
//        inspectEntityHierarchy(clone)
        return clone
    }
    
    internal func processLoadedAsset(_ result: LoadResult) {
        switch result {
        case .success(let entity, let key, _):
            entityTemplates[key] = entity
        case .failure(_, _, _):
            break
        }
    }
    
    // MARK: - Memory Management
    
    /// Aggressively cleans up all assets except those explicitly needed for playing phase
    func cleanupForPlayingPhase() async {
        print("\n=== Starting Aggressive Cleanup for Playing Phase ===")
        
        // Log initial state
        print("📊 Before cleanup - Template cache size: \(entityTemplates.count) entities")
        print("📊 Current templates: \(entityTemplates.keys.joined(separator: ", "))")
        
        // Only keep assembled_lab and cancer_cell for playing phase
        let essentialForPlaying = ["assembled_lab", "cancer_cell"]
        let keysToRemove = entityTemplates.keys.filter { !essentialForPlaying.contains($0) }
        
        print("\n🗑️ Aggressively removing \(keysToRemove.count) non-essential assets:")
        for key in keysToRemove {
            if let entity = entityTemplates[key] {
                print("\n🗑️ Removing asset: \(key)")
                // Use releaseEntity for thorough cleanup including audio
                releaseEntity(entity)
                entityTemplates.removeValue(forKey: key)
                print("✅ Released asset: \(key)")
            }
        }
        
        // Clear any remaining audio controllers
        let audioCount = audioControllers.count
        if audioCount > 0 {
            print("\n🔊 Clearing \(audioCount) audio controllers")
            audioControllers.removeAll()
        }
        
        // Log final state
        print("\n📊 After cleanup - Template cache size: \(entityTemplates.count) entities")
        print("🔒 Remaining assets: \(entityTemplates.keys.joined(separator: ", "))")
        print("✅ Completed aggressive cleanup for playing phase\n")
        
        // Force a garbage collection if possible
        #if DEBUG
        print("💭 Requesting memory cleanup")
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.1))
            print("💭 Memory cleanup requested")
        }
        #endif
    }

    /// Handles memory pressure by releasing non-essential assets
    func handleMemoryWarning() {
        print("\n⚠️ === Handling Memory Pressure ===")
        print("📊 Before cleanup - Template cache size: \(entityTemplates.count) entities")
        print("📊 Current templates: \(entityTemplates.keys.joined(separator: ", "))")
        
        // Clear ALL audio controllers immediately
        let audioCount = audioControllers.count
        if audioCount > 0 {
            print("\n🔊 Clearing \(audioCount) audio controllers")
            audioControllers.removeAll()
        }
        
        // Keep only absolute essentials based on current phase
        let essentialKeys = [
            "assembled_lab",
            "attack_cancer_environment",
            "adc",
            "cancer_cell"
        ]
        let nonEssentialKeys = entityTemplates.keys.filter { !essentialKeys.contains($0) }
        
        print("\n🔒 Essential assets to retain: \(essentialKeys)")
        print("🗑️ Non-essential assets to release: \(nonEssentialKeys)")
        
        // Release non-essential assets
        for key in nonEssentialKeys {
            if let entity = entityTemplates[key] {
                releaseEntity(entity)
                entityTemplates.removeValue(forKey: key)
                print("  - Released: \(key)")
            }
        }
        
        print("\n📊 After cleanup - Template cache size: \(entityTemplates.count) entities")
        print("🔒 Remaining assets: \(entityTemplates.keys.joined(separator: ", "))")
        print("✅ Memory pressure handling complete\n")
    }
    
    internal func validateTemplate(_ entity: Entity, category: AssetCategory) async {
        print("\n=== Validating \(category) Template ===")
        inspectEntityHierarchy(entity, level: 0)
    }
    
    /// Debug utility to inspect entity hierarchies
    public func inspectEntityHierarchy(_ entity: Entity, level: Int = 0, showComponents: Bool = true) {
        let indent = String(repeating: "  ", count: level)
        print("\(indent)Entity: \(entity.name)")
        if showComponents {
            print("\(indent)Components: \(entity.components.map { type(of: $0) })")
        }
        
        for child in entity.children {
            inspectEntityHierarchy(child, level: level + 1, showComponents: showComponents)
        }
    }
    
    /// Load an entity by name, using caching to avoid redundant loads
    func loadEntity(named name: String) async throws -> Entity {
        // First attempt: Check cache and clone to ensure each usage gets its own instance
        if let cachedEntity = entityTemplates[name] {
            return cachedEntity.clone(recursive: true)
        }

        do {
            // Second attempt: Load from bundle and handle protobuf errors
        let entity = try await Entity(named: name, in: realityKitContentBundle)
            // Clone again to ensure the loaded entity is independent and can be used multiple times
        return entity.clone(recursive: true)
        } catch {
            if error.localizedDescription.contains("protobuf") {
                print("❌ Protobuf error loading \(name): \(error)")
                throw AssetError.protobufError(name)
            }
            throw error
        }
    }
    
    // MARK: - On-Demand Asset Loading

    // Add a private mapping from our logical keys to actual asset names
    private let assetNameMappings: [String: String] = [
        "intro_environment": "IntroEnvironment",
        "intro_warp": "IntroWarp",
        "title_card": "outdoCancer",
        "lab_environment": "LabEnvironment",
        "lab_vo": "LabVO",
        "lab_audio": "LabAudio",
        "antibody_scene": "antibodyScene",
        "attack_cancer_environment": "AttackCancerEnvironment",
        "adc": "ADC-spawn",  // ADC asset name
        "cancer_cell": "CancerCell-spawn",  // Cancer cell asset name
        "game_start_vo": "AttackCancerGameStart_VO",  // Tutorial/game start VO
        "outro_environment": "OutroEnvironment"  // Outro environment asset
        // add further mappings as needed
    ]

    // Helper function to obtain the actual asset name from a key
    private func actualAssetName(for key: String, category: AssetCategory) -> String {
        return assetNameMappings[key] ?? key
    }

    /// Loads an asset by name on demand and caches it.
    func loadAsset(withName name: String, category: AssetCategory) async throws -> Entity {
        // For the assembled lab, use the specialized loader
        if name == "assembled_lab" {
            return try await loadAssembledLab()
        }
        
        // If already cached, return a clone of the cached asset
        if let cached = entityTemplates[name] {
            return cached.clone(recursive: true)
        }
        
        // Map the provided logical key to the actual resource name
        let actualName = actualAssetName(for: name, category: category)
        
        // Attempt to load from the RealityKitContent bundle using the actual asset name
        let entity = try await self.loadEntity(named: actualName)
        
        // Special handling for ADC asset
        if name == "adc" {
            if let innerRoot = await entity.children.first {
                print("✅ ADC template loaded (using inner Root with audio)")
                // Cache the inner root as the ADC template
                entityTemplates[name] = innerRoot
                return innerRoot.clone(recursive: true)
            } else {
                print("❌ Failed to find inner root in ADC-spawn")
                throw AssetError.resourceNotFound
            }
        }
        
        // Cache the loaded asset for future use using the logical key
        entityTemplates[name] = entity
        
        // Return a cloned copy so that modifications do not affect the cached template
        return entity.clone(recursive: true)
    }


    /// Instantiates an asset, returning a cloned instance.
    func instantiateAsset(withName name: String, category: AssetCategory) async throws -> Entity {
        return try await loadAsset(withName: name, category: category)
    }

    /// TODO remove this once we are sure the assets are loaded on demand
    /// Load all assets required for the entire app
    func loadAssets() async throws {
        loadingState = .loading(progress: 0)
        failedAssets.removeAll() // Clear previous failures
        
        var completedAssets = 0
        var totalAssets = 0  // Initialize task count
        
        do {
            try await withThrowingTaskGroup(of: LoadResult.self) { group in
                // Load different categories in parallel, updating totalAssets
             loadIntroEnvironmentAssets(group: &group, taskCount: &totalAssets)
             loadIntroWarpAssets(group: &group, taskCount: &totalAssets)
             loadLogoAssets(group: &group, taskCount: &totalAssets)
             loadTitleAssets(group: &group, taskCount: &totalAssets)
              loadLabEnvironmentAssets(group: &group, taskCount: &totalAssets)
              loadLabVO(group: &group, taskCount: &totalAssets)
            //   loadLabAudio(group: &group, taskCount: &totalAssets)
              loadLabEquipmentAssets(group: &group, taskCount: &totalAssets)
//               loadBuildADCEnvironmentAssets(group: &group, taskCount: &totalAssets)
              loadBuildADCAssets(group: &group, taskCount: &totalAssets)
           //    loadBuildADCAudio(group: &group, taskCount: &totalAssets)
              loadAttackCancerEnvironmentAssets(group: &group, taskCount: &totalAssets)
              loadAttackCancerGameStartVO(group: &group, taskCount: &totalAssets)
              loadCancerCellAssets(group: &group, taskCount: &totalAssets)
               loadTreatmentAssets(group: &group, taskCount: &totalAssets)
              loadOutroEnvironmentAssets(group: &group, taskCount: &totalAssets)
                
                // Process results with error handling
                for try await result in group {
                    completedAssets += 1
                    
                    switch result {
                    case .success(let entity, let key, _):
                        entityTemplates[key] = entity
                        // Success already logged by the loader
                        
                    case .failure(let key, let category, let error):
                        failedAssets.append(FailedAsset(key: key, category: category, error: error))
                        // Failure already logged by the loader
                    }
                    
                    let progress = Float(completedAssets) / Float(totalAssets)
                    loadingState = .loading(progress: progress)
                }
            }
            
            // After loading completes, report failures
            if !failedAssets.isEmpty {
                print("\n=== Asset Loading Report ===")
                print("Failed to load \(failedAssets.count) assets:")
                for failure in failedAssets {
                    print("- \(failure.key) (\(failure.category)): \(failure.error)")
                }
                print("========================\n")
            }
            
            loadingState = .completed
            
        } catch {
            print("Error in task group: \(error)")
            loadingState = .error(error)
            throw error
        }
    }

    /// Stores an audio controller for later cleanup
    func trackAudioController(_ controller: AudioPlaybackController, for entity: Entity) {
        audioControllers[entity.id] = controller
        print("📝 Tracking audio controller for entity: \(entity.name)")
    }
}
