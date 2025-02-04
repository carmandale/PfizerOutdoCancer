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
        
        let introAssets = [
            "intro_environment",
            "intro_warp",
        ]
        
        // Load intro assets with progress
        for (index, asset) in introAssets.enumerated() {
            print("📱 Loading intro asset: \(asset)")
            try await assetLoadingManager.loadAsset(withName: asset, category: .introEnvironment)
            let progress = Float(index + 1) / Float(introAssets.count + 1) // +1 for assembled_lab
            loadingProgress = progress
            print("✅ Loaded \(asset) - Progress: \(progress)")
        }
        
        // Preload assembled lab for portal
        print("📱 Preloading assembled lab for portal")
        try await assetLoadingManager.loadAsset(withName: "assembled_lab", category: .labEnvironment)
        loadingProgress = 1.0
        print("✅ Assembled lab preloaded")
        
        loadingState = .completed
        print("✅ Intro phase preparation complete")
    }
}
