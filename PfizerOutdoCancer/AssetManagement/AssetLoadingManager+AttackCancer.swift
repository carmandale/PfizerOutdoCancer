import Foundation
import RealityKit
import RealityKitContent

enum AssetLoadError: Error {
    case loadFailed(String)
    case missingComponent
}

extension AssetLoadingManager {
    
    internal func loadAttackCancerEnvironmentAssets(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
        group.addTask {
            print("Starting to load and assemble AttackCancerEnvironment")
            let assetRoot = await Entity()
            
            do {
                // Load base environment
                let attackCancerScene = try await self.loadEntity(named: "AttackCancerEnvironment")
                await assetRoot.addChild(attackCancerScene)
                
                // Store the actual environment
                await self.setAttackCancerEnvironment(assetRoot)
                
                print("Successfully assembled AttackCancerEnvironment")
                return .success(entity: assetRoot, key: "attack_cancer_environment", category: .attackCancerEnvironment)
            } catch {
                print("Failed to load AttackCancerEnvironment: \(error)")
                return .failure(key: "attack_cancer_environment", category: .attackCancerEnvironment, error: error)
            }
        }
        taskCount += 1
    }
    
    internal func loadAttackCancerGameStartVO(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
        group.addTask {
            print("Starting to load Attack Cancer Game Start VO")
            do {
                let entity = try await Entity(named: "AttackCancerGameStart_VO", in: realityKitContentBundle)
                print("Successfully loaded AttackCancerGameStart_VO")
                return .success(entity: entity, key: "game_start_vo", category: .cancerCell)
            } catch {
                print("Failed to load AttackCancerGameStart_VO: \(error)")
                return .failure(key: "game_start_vo", category: .cancerCell, error: error)
            }
        }
        taskCount += 1
    }
    
    internal func loadCancerCellAssets(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
        group.addTask {
            print("Starting to load CancerCell-spawn")
            do {
                let entity = try await Entity(named: "CancerCell-spawn", in: realityKitContentBundle)
                print("Successfully loaded CancerCell-spawn")
                return .success(entity: entity, key: "cancer_cell", category: .cancerCell)
            } catch {
                print("Failed to load CancerCell-spawn: \(error)")
                return .failure(key: "cancer_cell", category: .cancerCell, error: error)
            }
        }
        taskCount += 1
    }
    
    internal func loadTreatmentAssets(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
        group.addTask {
            print("Starting to load ADC-spawn")
            do {
                let adc = try await Entity(named: "ADC-spawn", in: realityKitContentBundle)
                print("Successfully loaded ADC-spawn")
                if let innerRoot = await adc.children.first {
                    print("ADC template loaded (using inner Root with audio)")
                    return .success(entity: innerRoot, key: "adc", category: .adc)
                }
                return .failure(key: "adc", category: .adc, error: AssetLoadError.loadFailed("No inner Root found"))
            } catch {
                print("Failed to load ADC-spawn: \(error)")
                return .failure(key: "adc", category: .adc, error: error)
            }
        }
        taskCount += 1
    }
} 

