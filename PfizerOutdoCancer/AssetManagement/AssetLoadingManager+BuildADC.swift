import Foundation
import RealityKit
import RealityKitContent

extension AssetLoadingManager {
    internal func loadBuildADCEnvironmentAssets(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
        group.addTask {
            print("Starting to load BuildADCEnvironment")
            do {
                let entity = try await self.loadEntity(named: "BuildADCEnvironment")
                print("Successfully loaded BuildADCEnvironment")
                return .success(entity: entity, key: "build_adc_environment", category: .buildADCEnvironment)
            } catch {
                print("Failed to load BuildADCEnvironment: \(error)")
                return .failure(key: "build_adc_environment", category: .buildADCEnvironment, error: error)
            }
        }
        taskCount += 1
    }
    
    
    // MARK: - Private Helper Methods
    
} 
