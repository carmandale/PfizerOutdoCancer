import Foundation
import RealityKit
import RealityKitContent

extension AssetLoadingManager {
    internal func loadIntroEnvironmentAssets(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
        
        group.addTask { () async throws -> LoadResult in
            print("Starting to load IntroEnvironment")
            let assetRoot = await Entity()
            
            do {
                // Load intro environment base
                print("Loading base IntroEnvironment")
                let introEnvironmentScene = try await self.loadEntity(named: "IntroEnvironment")
                await assetRoot.addChild(introEnvironmentScene)
                
                // Load and add intro audio
//                print("Assembling audio scene")
//                let introAudioScene = try await self.loadEntity(named: "IntroAudio")
//                await assetRoot.addChild(introAudioScene)
                
                print("Successfully assembled complete IntroEnvironment")
                return .success(entity: assetRoot, key: "intro_environment", category: .introEnvironment)
            } catch {
                print("Failed to load IntroEnvironment: \(error)")
                return .failure(key: "intro_environment", category: .introEnvironment, error: error)
            }
        }
        taskCount += 1
    }
    
    internal func loadLogoAssets(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
        group.addTask {
            print("Starting to load Pfizer logo")
            do {
                let entity = try await Entity(named: "logo", in: realityKitContentBundle)
                print("Successfully loaded Pfizer logo")
                return .success(entity: entity, key: "pfizer_logo", category: .cancerCell)
            } catch {
                print("Failed to load Pfizer logo: \(error)")
                return .failure(key: "pfizer_logo", category: .cancerCell, error: error)
            }
        }
        taskCount += 1
    }
    
    internal func loadTitleAssets(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
        group.addTask {
            print("Starting to load Title card")
            do {
                let entity = try await Entity(named: "outdoCancer", in: realityKitContentBundle)
                print("Successfully loaded Title card")
                return .success(entity: entity, key: "title_card", category: .cancerCell)
            } catch {
                print("Failed to load Title card: \(error)")
                return .failure(key: "title_card", category: .cancerCell, error: error)
            }
        }
        taskCount += 1
    }
    // MARK: - Private Helper Methods
    
} 
