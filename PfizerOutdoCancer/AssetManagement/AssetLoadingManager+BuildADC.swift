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
    
    internal func loadBuildADCAssets(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
        // Load antibody scene
        group.addTask {
            print("Starting to load antibodyScene")
            do {
                let entity = try await self.loadEntity(named: "antibodyScene")
                print("Successfully loaded antibodyScene")
                return .success(entity: entity, key: "antibody_scene", category: .buildADCEnvironment)
            } catch {
                print("Failed to load antibodyScene: \(error)")
                return .failure(key: "antibody_scene", category: .buildADCEnvironment, error: error)
            }
        }
        taskCount += 1
        
        // Load outline material
//        group.addTask {
//            print("Starting to load outline material")
//            do {
//                let materialEntity = try await Entity(named: "Materials/M_outline.usda", in: realityKitContentBundle)
//                if let sphereEntity = await materialEntity.findEntity(named: "Sphere"),
//                   let material = sphereEntity.components[ModelComponent.self]?.materials.first as? ShaderGraphMaterial {
//                    print("Successfully loaded outline material")
//                    return .success(entity: material, key: "outline_material", category: .buildADCEnvironment)
//                } else {
//                    print("Failed to extract outline material from entity")
//                    return .failure(key: "outline_material", category: .buildADCEnvironment, error: AssetError.materialNotFound)
//                }
//            } catch {
//                print("Failed to load outline material: \(error)")
//                return .failure(key: "outline_material", category: .buildADCEnvironment, error: error)
//            }
//        }
//        taskCount += 1
    }
    
    // internal func loadBuildADCAudio(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
    //     // Load pop sound
    //     group.addTask {
    //         print("Starting to load pop sound")
    //         do {
    //             let audioEntity = try await Entity(named: "antibodyScene.usda", in: realityKitContentBundle)
    //             if let popSound = await audioEntity.findEntity(named: "bubblepop_mp3") {
    //                 print("Successfully loaded pop sound")
    //                 return .success(entity: popSound, key: "pop_sound", category: .buildADCEnvironment)
    //             } else {
    //                 print("Failed to find pop sound in entity")
    //                 return .failure(key: "pop_sound", category: .buildADCEnvironment, error: AssetError.resourceNotFound)
    //             }
    //         } catch {
    //             print("Failed to load pop sound: \(error)")
    //             return .failure(key: "pop_sound", category: .buildADCEnvironment, error: error)
    //         }
    //     }
    //     taskCount += 1
        
    //     // Load voice over audio files
    //     let voiceOvers = [
    //         (name: "BuildADC_VO_1_mp3", key: "vo1"),
    //         (name: "BuildADC_VO_2_mp3", key: "vo2"),
    //         (name: "BuildADC_VO_3_mp3", key: "vo3"),
    //         (name: "BuildADC_VO_4_mp3", key: "vo4")
    //     ]
        
    //     for vo in voiceOvers {
    //         group.addTask {
    //             print("Starting to load \(vo.key)")
    //             do {
    //                 let audioEntity = try await Entity(named: "AttackCancerGameStart_VO.usda", in: realityKitContentBundle)
    //                 if let voSound = await audioEntity.findEntity(named: vo.name) {
    //                     print("Successfully loaded \(vo.key)")
    //                     return .success(entity: voSound, key: vo.key, category: .buildADCEnvironment)
    //                 } else {
    //                     print("Failed to find \(vo.key) in entity")
    //                     return .failure(key: vo.key, category: .buildADCEnvironment, error: AssetError.resourceNotFound)
    //                 }
    //             } catch {
    //                 print("Failed to load \(vo.key): \(error)")
    //                 return .failure(key: vo.key, category: .buildADCEnvironment, error: error)
    //             }
    //         }
    //         taskCount += 1
    //     }
    // }
    
    // MARK: - Private Helper Methods
    
} 
