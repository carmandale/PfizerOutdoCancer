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
    
    // Progress weights for different asset types
    private struct ProgressWeights {
        static let regular: Float = 0.7  // 70% weight for regular assets
        static let lab: Float = 0.3      // 30% weight for lab loading
        
        // Helper method to calculate weighted progress
        static func calculate(regularProgress: Float, labProgress: Float) -> Float {
            return (regularProgress * regular) + (labProgress * lab)
        }
    }
    
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
        Logger.debug("\n=== Starting Initial Asset Loading ===")
        
        // Initialize loading state and progress
        displayedProgress = 0.0
        assetLoadingManager.loadingState = .loading(progress: 0.0)
        
        await prepareIntroPhase()
        await transitionToPhase(.intro, adcDataModel: adcDataModel)
        Logger.debug("=== Asset Loading Complete ===")
    }
    
    func prepareIntroPhase() async {
        Logger.debug("=== Preparing Intro Phase Assets ===")
        
        var introAssets: [String] = []
        introAssets.append(contentsOf: [
            "intro_environment"
            // "intro_warp",
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
        
        // Reset progress tracking
        self.regularAssetsProgress = 0.0
        self.labLoadingProgress = 0.0
        
        // Load intro environment assets
        for key in allAssets {
            let category: AssetCategory
            if introAssets.contains(key) {
                category = .introEnvironment
            } else if attackAssets.contains(key) {
                category = .attackCancerEnvironment
            } else if labAssets.contains(key) {
                category = .labEnvironment
            } else {
                // Default case, should not happen
                Logger.debug("⚠️ Unknown asset category for key: \(key)")
                continue
            }
            
            do {
                if key == "assembled_lab" {
                    // Special handling for lab asset with progress reporting
                    _ = try await assetLoadingManager.loadAsset(
                        withName: key,
                        category: category,
                        progressCallback: { [weak self] labProgress in
                            guard let self = self else { return }
                            
                            // Store lab progress
                            self.labLoadingProgress = labProgress
                            
                            // Calculate combined progress
                            let combinedProgress = ProgressWeights.calculate(
                                regularProgress: self.regularAssetsProgress,
                                labProgress: self.labLoadingProgress
                            )
                            
                            // Update loading state with combined progress (no logging)
                            if combinedProgress >= 1.0 {
                                self.assetLoadingManager.loadingState = .completed
                            } else {
                                self.assetLoadingManager.loadingState = .loading(progress: combinedProgress)
                            }
                        }
                    )
                    Logger.debug("✅ Loaded lab environment")
                } else {
                    // Regular asset loading
                    _ = try await assetLoadingManager.loadAsset(withName: key, category: category)
                    completedAssets += 1
                    
                    // Update regular assets progress
                    let regularAssetCount = allAssets.count - labAssets.count
                    self.regularAssetsProgress = Float(completedAssets) / Float(regularAssetCount)
                    
                    // Calculate combined progress
                    let combinedProgress = ProgressWeights.calculate(
                        regularProgress: self.regularAssetsProgress,
                        labProgress: self.labLoadingProgress
                    )
                    
                    // Update loading state based on combined progress (no logging)
                    if combinedProgress >= 1.0 {
                        assetLoadingManager.loadingState = .completed
                    } else {
                        assetLoadingManager.loadingState = .loading(progress: combinedProgress)
                    }
                }
            } catch {
                Logger.debug("❌ Failed to load \(key): \(error)")
                // Use the generic error here
                assetLoadingManager.loadingState = .error(AppError.genericLoadingError)
                return // Exit the function on error
            }
        }
        Logger.debug("=== All Assets Loaded Successfully ===")
    }
}
