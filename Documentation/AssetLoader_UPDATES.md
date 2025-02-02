# Asset Loading Refactor Plan for VisionOS2

This document outlines the updated approach for asset management in our VisionOS2 application, moving from a preloading-everything model to an on-demand asset loading strategy. This refactor is designed to reduce memory pressure by loading assets only when needed and releasing them promptly when they are no longer in use.

## Overview

The current implementation uses a task-group based preloading system that loads all assets at startup. While this ensures assets are ready for immediate use, it can lead to memory errors and inefficient resource utilization, especially for large 3D assets in immersive experiences.

## New On-Demand Loading Strategy

- **On-Demand Loading:**  
  Each view (or its view model) will now call asynchronous methods to load the required assets only when the scene is visible. For example:
  ```swift
  let introEnvironment = try await AssetLoadingManager.shared.instantiateAsset(withName: "intro_environment", category: .introEnvironment)
  ```
  This method checks if the asset is already cached. If so, it returns a cloned copy; otherwise, it loads the asset from the RealityKitContent bundle and caches it.

- **Caching and Cloning:**
  The asset is cached as a "template" entity. Every time an asset is needed, a clone is returned. This allows individual instances to be modified without affecting the cached original.

- **Releasing Assets:**
  To free up memory, the new API includes:
  - `releaseAsset(withName:)` – releases a specific asset.
  - `releaseAssets(for:)` – releases all assets for a given category (using naming conventions or metadata).
  These methods allow view models to explicitly release assets when a scene is dismissed.

## Deprecation of Preloading Methods

- The existing group-based preloading methods (e.g., `loadAssets()`, `loadIntroEnvironmentAssets(…)`, etc.) will be deprecated for now.
- Critical assembly processes, such as the lab scene assembly (`loadPopulatedLabScene` and related methods), will remain intact. The lab view will trigger these processes on-demand when assets are loaded.
- This staged deprecation ensures that if any issues arise from the refactor, we can fall back to the legacy behavior without impacting critical functionality.

## Migration Plan

1. **Intro Scene Update:**
   - Modify `IntroView.swift` to load assets on-demand using the new API.
   - Remove any preloading logic.
   - After the intro scene is dismissed, call `AssetLoadingManager.shared.releaseAsset(withName: "intro_environment")` to free up memory.

2. **Lab Scene Update (Next Phase):**
   - Update the lab view to use the new on-demand API.
   - Ensure that the lab assembly logic is invoked correctly when its assets are loaded.

3. **Testing and Validation:**
   - Start by testing the Intro scene with the new on-demand approach.
   - Validate that assets are loaded and released as expected.
   - Incrementally update and test the Lab view after confirming the success with Intro.

## Alignment with VisionOS2 Best Practices

- **Memory Efficiency:** On-demand loading minimizes memory footprint by loading only the assets that are currently needed.
- **Asynchronous & Lazy Loading:** Leveraging async/await promotes efficient asset loading, which is critical in immersive environments.
- **Explicit Asset Lifecycle Management:** Provides better control over asset usage and cleanup, essential for managing resources on VisionOS devices.

## Conclusion

This refactor aims to make our asset management system more efficient and robust against memory errors while preserving critical asset assembly workflows—particularly for the lab scene. We will begin by updating the Intro scene to use the new on-demand API and then extend the refactor to the Lab view in the next phase.

If there are any questions or further clarifications needed, please let's discuss before proceeding.

Below is a very simple, Swift‐like pseudocode example that demonstrates how you might structure your asset loading and releasing logic across an asset loader, app model, view model, and immersive view. In a real app you'd use RealityKit's asynchronous loading (for example, using async/await or callbacks from methods like Entity.loadAsync(named:)), but this pseudocode is meant to illustrate the pattern following visionOS 2 best practices.

// AssetLoader.swift
// A simple asset loader that caches assets and can release them.
class AssetLoader {
    // A cache to hold loaded assets (could be RealityKit entities, audio players, etc.)
    private var assetCache: [String: Any] = [:]

    // Loads an asset asynchronously and caches it.
    func loadAsset(named name: String, completion: @escaping (Any?) -> Void) {
        // If already loaded, return the cached asset.
        if let cachedAsset = assetCache[name] {
            completion(cachedAsset)
            return
        }
        // Simulate asynchronous asset loading.
        loadAssetAsync(named: name) { asset in
            self.assetCache[name] = asset
            completion(asset)
        }
    }
    
    // Releases (un-caches) a specific asset.
    func releaseAsset(named name: String) {
        assetCache.removeValue(forKey: name)
    }
    
    // Pseudocode for an asynchronous asset load.
    private func loadAssetAsync(named name: String, completion: @escaping (Any?) -> Void) {
        // In a real implementation, use RealityKit's asynchronous API.
        // For example: Entity.loadAsync(named: name) { result in ... }
        // Here we simply simulate the loaded asset.
        let simulatedAsset = "Asset:\(name)"  // This represents a loaded asset.
        completion(simulatedAsset)
    }
}

// AppModel.swift
// The central model that knows about scenes and their required assets.
class AppModel {
    let assetLoader = AssetLoader()
    
    // Dictionary to track assets currently loaded for a scene.
    var loadedAssets: [String: Any] = [:]
    
    // Loads assets based on the scene identifier.
    func loadSceneAssets(for scene: String, completion: @escaping () -> Void) {
        // For example, the intro has heavy spatial audio.
        if scene == "intro" {
            assetLoader.loadAsset(named: "IntroSpatialAudio") { asset in
                if let asset = asset {
                    self.loadedAssets["IntroSpatialAudio"] = asset
                }
                completion()
            }
        }
        // The lab scene has heavy 3D models and audio.
        else if scene == "lab" {
            assetLoader.loadAsset(named: "Lab3DModel") { asset in
                if let asset = asset {
                    self.loadedAssets["Lab3DModel"] = asset
                }
                completion()
            }
        }
    }
    
    // Releases assets that are no longer needed.
    func releaseSceneAssets(for scene: String) {
        if scene == "intro" {
            assetLoader.releaseAsset(named: "IntroSpatialAudio")
            loadedAssets.removeValue(forKey: "IntroSpatialAudio")
        }
        // You might choose to keep lab assets loaded if they're used frequently.
    }
}

// ViewModel.swift
// The view model that manages scene transitions and coordinates with the AppModel.
class ViewModel {
    let appModel: AppModel
    // Tracks the current scene identifier.
    var currentScene: String = ""
    
    init(appModel: AppModel) {
        self.appModel = appModel
    }
    
    // Transitions to a new scene, loading and releasing assets as needed.
    func transitionToScene(_ scene: String, completion: @escaping () -> Void) {
        // Example: If transitioning away from the intro, release its assets.
        if currentScene == "intro" && scene != "intro" {
            appModel.releaseSceneAssets(for: "intro")
        }
        
        // Load assets required for the new scene.
        appModel.loadSceneAssets(for: scene) {
            self.currentScene = scene
            completion()
        }
    }
}

// ImmersiveView.swift
// The immersive view that presents content using loaded assets.
struct ImmersiveView {
    let viewModel: ViewModel
    
    // This function simulates displaying a scene.
    func display() {
        if viewModel.currentScene == "intro" {
            // Retrieve the intro audio asset and configure RealityKit audio components.
            if let introAudio = viewModel.appModel.loadedAssets["IntroSpatialAudio"] {
                // Pseudocode: integrate introAudio into your RealityKit scene.
                print("Displaying Intro Scene with asset: \(introAudio)")
            }
        } else if viewModel.currentScene == "lab" {
            // Retrieve the lab 3D model asset.
            if let labAsset = viewModel.appModel.loadedAssets["Lab3DModel"] {
                // Pseudocode: add labAsset to the RealityKit scene graph.
                print("Displaying Lab Scene with asset: \(labAsset)")
            }
        }
    }
}

// Usage Example
// This shows how the various pieces interact during a scene transition.
let appModel = AppModel()
let viewModel = ViewModel(appModel: appModel)
let immersiveView = ImmersiveView(viewModel: viewModel)

// Transition to the Intro scene.
viewModel.transitionToScene("intro") {
    immersiveView.display()
    
    // Later, after the intro is finished, transition to the Lab scene.
    viewModel.transitionToScene("lab") {
        immersiveView.display()
    }
}

Explanation
	1.	AssetLoader:
– Loads assets asynchronously and caches them.
– Provides a method to release assets when they're no longer needed.
	2.	AppModel:
– Knows which assets are needed for each scene.
– Uses the asset loader to load (and later release) these assets.
	3.	ViewModel:
– Manages scene transitions.
– Calls the app model to load the new scene's assets and releases assets from scenes that are no longer active.
	4.	ImmersiveView:
– Uses the view model's state to determine which scene to display.
– Retrieves the appropriate assets from the app model to integrate with RealityKit's scene graph.

This pseudocode demonstrates a simple, modular approach to asset management that follows best practices by loading only what you need, caching assets for reuse, and releasing them when they're no longer needed—all key strategies for optimizing memory usage in visionOS 2 with RealityKit.