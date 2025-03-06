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
    
    // Helper method to log detailed progress visualization
    private func logProgressVisualization(regular: Float, lab: Float, combined: Float) {
        let regularBar = String(repeating: "█", count: Int(regular * 20))
        let labBar = String(repeating: "█", count: Int(lab * 20))
        let combinedBar = String(repeating: "█", count: Int(combined * 20))
        
        print("""
        📊 Progress Visualization:
        Regular: [\(regularBar.padding(toLength: 20, withPad: " ", startingAt: 0))] \(Int(regular * 100))%
        Lab:     [\(labBar.padding(toLength: 20, withPad: " ", startingAt: 0))] \(Int(lab * 100))%
        TOTAL:   [\(combinedBar.padding(toLength: 20, withPad: " ", startingAt: 0))] \(Int(combined * 100))%
        """)
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
        print("\n=== Starting Initial Asset Loading ===")
        print("🔍 Current phase: \(currentPhase)")
        print("🔍 Loading state: \(assetLoadingManager.loadingState)")
        
        // Initialize loading state and progress
        displayedProgress = 0.0
        assetLoadingManager.loadingState = .loading(progress: 0.0)
        
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
        
        // Reset progress tracking
        self.regularAssetsProgress = 0.0
        self.labLoadingProgress = 0.0
        
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
                            
                            // Log progress visualization
                            self.logProgressVisualization(
                                regular: self.regularAssetsProgress,
                                lab: self.labLoadingProgress,
                                combined: combinedProgress
                            )
                            
                            // Update loading state with combined progress
                            print("🔄 Combined progress update: \(combinedProgress)")
                            if combinedProgress >= 1.0 {
                                self.assetLoadingManager.loadingState = .completed
                            } else {
                                self.assetLoadingManager.loadingState = .loading(progress: combinedProgress)
                            }
                        }
                    )
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
                    
                    print("✅ Loaded \(key) - Regular Progress: \(self.regularAssetsProgress)")
                    
                    // Log progress visualization
                    self.logProgressVisualization(
                        regular: self.regularAssetsProgress,
                        lab: self.labLoadingProgress,
                        combined: combinedProgress
                    )
                    
                    // Update loading state based on combined progress
                    print("🔄 Combined progress update: \(combinedProgress)")
                    if combinedProgress >= 1.0 {
                        assetLoadingManager.loadingState = .completed
                    } else {
                        assetLoadingManager.loadingState = .loading(progress: combinedProgress)
                    }
                }
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
