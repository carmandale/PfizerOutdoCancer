//
//  AssetLoadingManager+AppAssets.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman
//

import Foundation
import RealityKit

extension AssetLoadingManager {
    /// Loads all app-specific assets in the correct order
    /// - Parameter adcDataModel: The ADC data model containing color selections
    /// - Returns: The loaded ADC template entity
    func loadAppAssets(adcDataModel: ADCDataModel) async throws -> Entity {
        Logger.debug("\n=== 🚀 STARTING APP ASSET LOAD ===")
        loadingState = .loading(progress: 0.0)
        
        do {
            // Load ADC template first
            let template = try await instantiateAsset(
                withName: "adc",
                category: .adc
            )
            
            // Load intro assets
            let introAssets = [
                "intro_environment"
                // "intro_warp",
            ]
            
            // Load attack assets
            let attackAssets = [
                "attack_cancer_environment",
                "cancer_cell"
            ]
            
            // Load lab assets
            let labAssets = [
                "assembled_lab"
            ]
            
            // Load all assets concurrently
            try await withThrowingTaskGroup(of: LoadResult.self) { group in
                let allAssets = introAssets + attackAssets + labAssets
                for assetName in allAssets {
                    group.addTask { () async throws -> LoadResult in
                        Logger.debug("Starting to load asset: \(assetName)")
                        
                        guard let category = AssetCategory(assetName: assetName) else {
                            Logger.error("Failed to determine category for asset: \(assetName)")
                            return .failure(
                                key: assetName,
                                category: .labEquipment,
                                error: AppError.assetLoadingError(description: "Invalid category for asset: \(assetName)")
                            )
                        }
                        
                        do {
                            let entity = try await self.instantiateAsset(
                                withName: assetName,
                                category: category
                            )
                            return .success(entity: entity, key: assetName, category: category)
                        } catch {
                            Logger.error("Failed to load asset: \(assetName), error: \(error)")
                            return .failure(
                                key: assetName,
                                category: category,
                                error: AppError.assetLoadingError(description: error.localizedDescription)
                            )
                        }
                    }
                }
                
                // Process results
                for try await result in group {
                    processLoadedAsset(result)
                }
            }
            
            Logger.debug("=== ✅ REALITYKIT ASSETS LOADED ===\n")
            loadingState = .completed
            return template
            
        } catch {
            Logger.error("""
            
            ❌ APP ASSET LOAD FAILED
            └─ Error: \(error.localizedDescription)
            """)
            loadingState = .error(error)
            throw error
        }
    }
}
