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

/// Categories of assets in the lab environment
enum AssetCategory {
    case introEnvironment
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
    
    /// Loaded lab environment entity
    var labEnvironment: Entity?
    
    /// Loaded attack cancer environment entity
    var attackCancerEnvironment: Entity?
    
    // MARK: - Public Methods
    
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
                loadLabEnvironmentAssets(group: &group, taskCount: &totalAssets)
                loadLabEquipmentAssets(group: &group, taskCount: &totalAssets)
                loadBuildADCEnvironmentAssets(group: &group, taskCount: &totalAssets)
                loadAttackCancerEnvironmentAssets(group: &group, taskCount: &totalAssets)
                loadCancerCellAssets(group: &group, taskCount: &totalAssets)
                loadTreatmentAssets(group: &group, taskCount: &totalAssets)
                
                // Process results with error handling
                for try await result in group {
                    completedAssets += 1
                    
                    switch result {
                    case .success(let entity, let key, let category):
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
    
    /// Clear unused templates when memory pressure is high
    func handleMemoryWarning() {
        // Keep essential templates, clear others that can be reloaded
        let essentialKeys = ["lab_environment", "cancer_cell"]
        entityTemplates = entityTemplates.filter { essentialKeys.contains($0.key) }
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
        if let cachedEntity = entityTemplates[name] {
            return cachedEntity.clone(recursive: true)
        }

        // Only load, don't cache - caching should be handled by the caller
        let entity = try await Entity(named: name, in: realityKitContentBundle)
        return entity.clone(recursive: true)
    }
}
