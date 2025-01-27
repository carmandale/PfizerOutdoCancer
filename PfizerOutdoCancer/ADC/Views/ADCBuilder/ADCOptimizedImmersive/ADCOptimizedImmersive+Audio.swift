import SwiftUI
import RealityKit
import RealityKitContent
import OSLog

extension ADCOptimizedImmersive {
    
    // MARK: - Audio Functions
    
    func prepareAudioEntities() async {
        // Load audio resources
        if let resource = try? await AudioFileResource(named: "/Root/bubblepop_mp3", from: "antibodyScene.usda", in: realityKitContentBundle) {
            popAudioFileResource = resource
            os_log(.debug, "ITR..ADCOptimizedImmersive: ✅ Successfully loaded pop sound")
            
            // Create pop sound entity with spatial audio
            let popSource = Entity()
            popSource.name = "PopSource"
            popSource.components.set(SpatialAudioComponent(directivity: .beam(focus: 1.0))) 
            if let popAudioFileResource = popAudioFileResource {
                popAudioPlaybackController = popSource.prepareAudio(popAudioFileResource)
                if popAudioPlaybackController != nil {
                    os_log(.debug, "ITR..ADCOptimizedImmersive: ✅ Successfully prepared pop sound controller")
                } else {
                    os_log(.error, "ITR..ADCOptimizedImmersive: ❌ Failed to create pop sound controller")
                }
            }
            self.popAudioEntity = popSource
            
            // Attach pop sound to target entities
            if let mainEntity {
                mainEntity.addChild(popSource)
                os_log(.debug, "ITR..ADCOptimizedImmersive: ✅ Successfully attached pop sound to target linker")
            }
            if let mainEntity {
                mainEntity.addChild(popSource)
                os_log(.debug, "ITR..ADCOptimizedImmersive: ✅ Successfully attached pop sound to target payload")
            }
        } else {
            os_log(.error, "ITR..ADCOptimizedImmersive: ❌ Error loading pop sound from antibodyScene.usda")
        }

        if let resource = try? await AudioFileResource(named: "/Root/BuildADC_VO_1_mp3", from: "BuildADC_VO.usda", in: realityKitContentBundle) {
            vo1Audio = resource
            os_log(.debug, "ITR..ADCOptimizedImmersive: ✅ Successfully loaded VO1")
        }
        if let resource = try? await AudioFileResource(named: "/Root/BuildADC_VO_2_mp3", from: "BuildADC_VO.usda", in: realityKitContentBundle) {
            vo2Audio = resource
            os_log(.debug, "ITR..ADCOptimizedImmersive: ✅ Successfully loaded VO2")
        }
        if let resource = try? await AudioFileResource(named: "/Root/BuildADC_VO_3_mp3", from: "BuildADC_VO.usda", in: realityKitContentBundle) {
            vo3Audio = resource
            os_log(.debug, "ITR..ADCOptimizedImmersive: ✅ Successfully loaded VO3")
        }
        if let resource = try? await AudioFileResource(named: "/Root/BuildADC_VO_4_mp3", from: "BuildADC_VO.usda", in: realityKitContentBundle) {
            vo4Audio = resource
            os_log(.debug, "ITR..ADCOptimizedImmersive: ✅ Successfully loaded VO4")
        }

        // Create voice-over entity with spatial audio - attached to main view entity
        let voiceOverSource = Entity()
        voiceOverSource.name = "VoiceOverSource"
        voiceOverSource.components.set(SpatialAudioComponent(directivity: .beam(focus: 1.0)))
        if let mainEntity {
            mainEntity.addChild(voiceOverSource)
        }
        self.voiceOverAudioEntity = voiceOverSource
        os_log(.debug, "ITR..ADCOptimizedImmersive: ✅ Successfully set up voice over entity")
    }

    func attachPopSoundToTarget(_ target: Entity) {
        if let popSound = popAudioEntity {
            target.addChild(popSound)
        }
    }

    func playPopSound() {
        os_log(.debug, "ITR..playPopSound(): Starting pop sound playback...")
        
        // System 1: Using bubblePopSound toggle
        os_log(.debug, "ITR..playPopSound(): 🔊 SYSTEM 1 - Triggering bubblePopSound toggle")
        bubblePopSound.toggle()
        
        // System 2: Using audioStorage (disabled for now)
        /*if let storage = audioStorage {
            os_log(.debug, "ITR..playPopSound(): 🔊 SYSTEM 2 - Attempting audioStorage playback")
            if dataModel.adcBuildStep == 2, // Linkers step
               dataModel.linkersWorkingIndex < adcLinkers.count {
                storage.playPopSound(at: adcLinkers[dataModel.linkersWorkingIndex].position)
            } else if dataModel.adcBuildStep == 3, // Payloads step
                      dataModel.payloadsWorkingIndex < adcPayloadsInner.count {
                storage.playPopSound(at: adcPayloadsInner[dataModel.payloadsWorkingIndex].position)
            }
        }*/
    }

    @MainActor
    func playSpatialAudio(step: Int) async throws {
        os_log(.debug, "ITR..playSpatialAudio(): Playing spatial audio for step \(step)")
        
        dataModel.isVOPlaying = true
        
        // Stop any currently playing VO
        if let controller = currentVOController {
            controller.stop()
            currentVOController = nil
        }
        
        // Get appropriate VO resource
        let voResource: AudioFileResource? = switch step {
            case 0: vo1Audio
            case 1: vo2Audio
            case 2: vo3Audio
            case 3: vo4Audio
            default: nil
        }
        
        guard let voResource,
              let voEntity = voiceOverAudioEntity else {
            os_log(.error, "ITR..playSpatialAudio(): Missing VO resource or entity for step \(step)")
            throw NSError(domain: "ADCOptimizedImmersive", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing VO resource or entity"])
        }
        
        // Create and play VO with completion handling
        return await withCheckedContinuation { continuation in
            currentVOController = voEntity.prepareAudio(voResource)
            currentVOController?.completionHandler = {
                os_log(.debug, "ITR..playSpatialAudio(): VO completed for step \(step)")
                dataModel.isVOPlaying = false
                continuation.resume()
            }
            currentVOController?.play()
            os_log(.debug, "ITR..playSpatialAudio(): Started playing VO for step \(step)")
        }
    }

    func playVO1() async {
        os_log(.debug, "ITR..playVO1(): Starting...")
        if let voiceOverAudioEntity {
            os_log(.debug, "ITR..playVO1(): ✅ Found voiceOverAudioEntity")
            if let vo1Audio {
                os_log(.debug, "ITR..playVO1(): ✅ Found vo1Audio")
                let controller = voiceOverAudioEntity.prepareAudio(vo1Audio)
                currentVOController = controller
                if let controller = currentVOController {
                    controller.play()
                    os_log(.debug, "ITR..playVO1(): ✅ Play called successfully")
                } else {
                    os_log(.error, "ITR..playVO1(): ❌ No controller")
                }
            } else {
                os_log(.error, "ITR..playVO1(): ❌ No vo1Audio")
            }
        } else {
            os_log(.error, "ITR..playVO1(): ❌ No voiceOverAudioEntity")
        }
    }

    func playVO2() async {
        os_log(.debug, "ITR..playVO2(): Starting...")
        if let voiceOverAudioEntity {
            os_log(.debug, "ITR..playVO2(): ✅ Found voiceOverAudioEntity")
            if let vo2Audio {
                os_log(.debug, "ITR..playVO2(): ✅ Found vo2Audio")
                let controller = voiceOverAudioEntity.prepareAudio(vo2Audio)
                currentVOController = controller
                if let controller = currentVOController {
                    controller.play()
                    os_log(.debug, "ITR..playVO2(): ✅ Play called successfully")
                } else {
                    os_log(.error, "ITR..playVO2(): ❌ No controller")
                }
            } else {
                os_log(.error, "ITR..playVO2(): ❌ No vo2Audio")
            }
        } else {
            os_log(.error, "ITR..playVO2(): ❌ No voiceOverAudioEntity")
        }
    }

    func playVO3() async {
        os_log(.debug, "ITR..playVO3(): Starting...")
        if let voiceOverAudioEntity {
            os_log(.debug, "ITR..playVO3(): ✅ Found voiceOverAudioEntity")
            if let vo3Audio {
                os_log(.debug, "ITR..playVO3(): ✅ Found vo3Audio")
                let controller = voiceOverAudioEntity.prepareAudio(vo3Audio)
                currentVOController = controller
                if let controller = currentVOController {
                    controller.play()
                    os_log(.debug, "ITR..playVO3(): ✅ Play called successfully")
                } else {
                    os_log(.error, "ITR..playVO3(): ❌ No controller")
                }
            } else {
                os_log(.error, "ITR..playVO3(): ❌ No vo3Audio")
            }
        } else {
            os_log(.error, "ITR..playVO3(): ❌ No voiceOverAudioEntity")
        }
    }

    func playVO4() async {
        os_log(.debug, "ITR..playVO4(): Starting...")
        if let voiceOverAudioEntity {
            os_log(.debug, "ITR..playVO4(): ✅ Found voiceOverAudioEntity")
            if let vo4Audio {
                os_log(.debug, "ITR..playVO4(): ✅ Found vo4Audio")
                let controller = voiceOverAudioEntity.prepareAudio(vo4Audio)
                currentVOController = controller
                if let controller = currentVOController {
                    controller.play()
                    os_log(.debug, "ITR..playVO4(): ✅ Play called successfully")
                } else {
                    os_log(.error, "ITR..playVO4(): ❌ No controller")
                }
            } else {
                os_log(.error, "ITR..playVO4(): ❌ No vo4Audio")
            }
        } else {
            os_log(.error, "ITR..playVO4(): ❌ No voiceOverAudioEntity")
        }
    }
}
