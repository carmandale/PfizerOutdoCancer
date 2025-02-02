//
//  AssetLoadingManager+Outro.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 1/8/25.
//


import Foundation
import RealityKit
import RealityKitContent

extension AssetLoadingManager {
    internal func loadOutroEnvironmentAssets(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
        
        group.addTask { () async throws -> LoadResult in
            print("Starting to load OutroEnvironment")
            let assetRoot = await Entity()
            
            do {
                // Load intro environment base
                print("Loading base OutroEnvironment")
                let outroEnvironmentScene = try await self.loadEntity(named: "OutroEnvironment")
                await assetRoot.addChild(outroEnvironmentScene)
                
                // Store the actual environment
//                await self.setOutroEnvironment(assetRoot)
                
                // Add IBL
                try await IBLUtility.addImageBasedLighting(to: assetRoot, imageName: "metro_noord_2k")
                
                print("Successfully assembled complete OutroEnvironment")
                return .success(entity: assetRoot, key: "outro_environment", category: .outroEnvironment)
            } catch {
                print("Failed to load OutroEnvironment: \(error)")
                return .failure(key: "outro_environment", category: .outroEnvironment, error: error)
            }
        }
        taskCount += 1
    }
}
