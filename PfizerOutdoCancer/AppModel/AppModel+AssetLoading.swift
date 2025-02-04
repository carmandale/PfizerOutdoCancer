//
//  AppModel+AssetLoading.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 12/10/24.
//

extension AppModel {
    // MARK: - Asset Loading
    
    var isLoadingAssets: Bool {
        if case .loading = assetLoadingManager.state {
            return true
        }
        return false
    }
    
    var assetsLoaded: Bool {
        if case .completed = assetLoadingManager.state {
            return true
        }
        return false
    }
    
    func startLoading() async {
        print("\n=== Starting Initial Asset Loading ===")
        do {
            try await prepareIntroPhase()
            await transitionToPhase(.ready)
        } catch {
            print("❌ Error loading initial assets: \(error)")
            loadingState = .error
            await transitionToPhase(.error)
        }
    }
    
    func prepareIntroPhase() async throws {
        print("\n=== Preparing Intro Phase ===")
        loadingState = .loading
        loadingProgress = 0
        
        // All assets to preload
        let assetsToLoad = [
            // Intro assets
            ("intro_environment", AssetCategory.introEnvironment),
            ("intro_warp", AssetCategory.introEnvironment),
            
            // Playing phase essential assets (no audio)
            ("attack_cancer_environment", AssetCategory.attackCancerEnvironment),
            ("adc", AssetCategory.adc),
            ("cancer_cell", AssetCategory.cancerCell),
            
            // Essential lab asset
            ("assembled_lab", AssetCategory.labEnvironment)
        ]
        
        // Load all assets with progress
        for (index, (asset, category)) in assetsToLoad.enumerated() {
            print("📱 Loading asset: \(asset)")
            try await assetLoadingManager.loadAsset(withName: asset, category: category)
            let progress = Float(index + 1) / Float(assetsToLoad.count)
            loadingProgress = progress
            print("✅ Loaded \(asset) - Progress: \(progress)")
        }
        
        loadingProgress = 1.0
        loadingState = .completed
        print("✅ Initial asset loading complete")
    }
}
