//
//  AppModel+AssetLoading.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 12/10/24.
//

import SwiftUI

// Define a generic error to use
enum AppError: Error {
    case genericLoadingError
}

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
    
    struct AssetToLoad {
        let name: String
        let category: AssetCategory
        let weight: Float  // Relative weight for progress calculation
    }
    
    func startLoading(adcDataModel: ADCDataModel) async {
        print("\n=== Starting Initial Asset Loading ===")
        print("🔍 Current phase: \(currentPhase)")
        print("🔍 Loading state: \(assetLoadingManager.loadingState)")
        
        // Reset the asset loading manager
        // assetLoadingManager.reset()
        
        print("🔄 Starting prepareIntroPhase...")
        await prepareIntroPhase()
        print("✅ prepareIntroPhase completed")
        print("🔄 Transitioning to .intro...")
        await transitionToPhase(.intro, adcDataModel: adcDataModel)
        print("✅ Transition to .intro completed")
    }
    
    func prepareIntroPhase() async {
        print("\n=== Preparing Intro Phase ===")
        print("🔍 Current phase before loading: \(currentPhase)")
        print("🔍 Loading state: \(assetLoadingManager.loadingState)")
        
        var introAssets: [String] = []
        introAssets.append(contentsOf: [
            "intro_environment",
            "intro_warp",
        ])
        
        var attackAssets: [String] = []
        attackAssets.append(contentsOf: [
            "attack_cancer_environment",
            "adc",
            "cancer_cell"
        ])
        
        var labAssets: [String] = []
        labAssets.append(contentsOf: [
            "assembled_lab"
        ])
        
        let allAssets = introAssets + attackAssets + labAssets
        
        var completedAssets = 0
        
        // Load intro environment assets
        for key in allAssets {
            print("📱 Loading asset: \(key)")
            
            let category: AssetCategory
            if introAssets.contains(key) {
                category = .introEnvironment
            } else if attackAssets.contains(key) {
                category = .attackCancerEnvironment
            } else if labAssets.contains(key) {
                category = .labEnvironment
            } else {
                // Default case, should not happen
                print("⚠️ Unknown asset category for key: \(key)")
                continue
            }
            
            do {
                _ = try await assetLoadingManager.loadAsset(withName: key, category: category)
                completedAssets += 1
                let progress = Float(completedAssets) / Float(allAssets.count)
                print("✅ Loaded \(key) - Progress: \(progress)")
            } catch {
                print("❌ Failed to load \(key): \(error)")
                // Use the generic error here
                assetLoadingManager.loadingState = .error(AppError.genericLoadingError)
                return // Exit the function on error
            }
        }
        print("✅ prepareIntroPhase completed")
    }
}
