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