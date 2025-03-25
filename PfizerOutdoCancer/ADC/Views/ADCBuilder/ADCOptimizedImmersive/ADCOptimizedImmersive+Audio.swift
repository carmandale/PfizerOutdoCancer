import SwiftUI
import RealityKit
import RealityKitContent
import OSLog

extension ADCOptimizedImmersive {
    
    // MARK: - Audio Functions
    
    func prepareAudioEntities() async {
        // Load audio resources
        if let resource = try? await AudioFileResource(named: "/Root/clickPop3_wav", from: "antibodyScene.usda", in: realityKitContentBundle) {
            popAudioFileResource = resource
            os_log(.debug, "ITR..ADCOptimizedImmersive: ✅ Successfully loaded pop sound")
            
            // Create pop sound entity with spatial audio
            let popSource = Entity()
            popSource.name = "PopSource"
            popSource.components.set(SpatialAudioComponent(
                gain: -6.0,  
                directivity: .beam(focus: 1.0)
            ))
            if let popAudioFileResource = popAudioFileResource {
                    popAudioPlaybackController = popSource.prepareAudio(popAudioFileResource)
                if popAudioPlaybackController != nil {
                    os_log(.debug, "ITR..ADCOptimizedImmersive: ✅ Successfully prepared pop sound controller")
                } else {
                    os_log(.error, "ITR..ADCOptimizedImmersive: ❌ Failed to create pop sound controller")
                }
            }
            self.popAudioEntity = popSource
            
            // Detach pop sound from main entity
            if let mainEntity {
                mainEntity.removeChild(popSource)
                os_log(.debug, "ITR..ADCOptimizedImmersive: ✅ Successfully detached pop sound from main entity")
            }
        } else {
            os_log(.error, "ITR..ADCOptimizedImmersive: ❌ Error loading bubblePop file group from antibodyScene.usda")
        }

        if let resource = try? await AudioFileResource(named: "/Root/v07_785793_buildADC_VO_1_wav", from: "BuildADC_VO.usda", in: realityKitContentBundle) {
            vo1Audio = resource
            os_log(.debug, "ITR..ADCOptimizedImmersive: ✅ Successfully loaded VO1")
        }
        if let resource = try? await AudioFileResource(named: "/Root/v07_785793_buildADC_VO_2_wav", from: "BuildADC_VO.usda", in: realityKitContentBundle) {
            vo2Audio = resource
            os_log(.debug, "ITR..ADCOptimizedImmersive: ✅ Successfully loaded VO2")
        }
        if let resource = try? await AudioFileResource(named: "/Root/v07_785793_buildADC_VO_3_wav", from: "BuildADC_VO.usda", in: realityKitContentBundle) {
            vo3Audio = resource
            os_log(.debug, "ITR..ADCOptimizedImmersive: ✅ Successfully loaded VO3")
        }
        if let resource = try? await AudioFileResource(named: "/Root/v07_785793_buildADC_VO_4_wav", from: "BuildADC_VO.usda", in: realityKitContentBundle) {
            vo4Audio = resource
            os_log(.debug, "ITR..ADCOptimizedImmersive: ✅ Successfully loaded VO4")
        }
        if let resource = try? await AudioFileResource(named: "/Root/ADC_Build_Complete_1_wav", from: "BuildADC_VO.usda", in: realityKitContentBundle) {
            completionAudio = resource
            os_log(.debug, "ITR..ADCOptimizedImmersive: ✅ Successfully loaded completion sound")
        }
        if let resource = try? await AudioFileResource(named: "/Root/v07_785793_nice_job_wav", from: "BuildADC_VO.usda", in: realityKitContentBundle) {
            niceJobAudio = resource
            os_log(.debug, "ITR..ADCOptimizedImmersive: ✅ Successfully loaded nice job sound")
        }

        // Create voice-over entity with spatial audio - attached to main view entity
        let voiceOverSource = Entity()
        voiceOverSource.name = "VoiceOverSource"

        // Conditionally set up the audio entity to be spatial or channel-based
        if useChannelAudioForVO {
            voiceOverSource.components.set(ChannelAudioComponent(
                gain: 0.0  // 0 dB = unity gain
            ))
            os_log(.debug, "ITR..ADCOptimizedImmersive: ✅ Using channel audio for voice over")
        } else {
            voiceOverSource.components.set(SpatialAudioComponent(directivity: .beam(focus: 1.0)))
            os_log(.debug, "ITR..ADCOptimizedImmersive: ✅ Using spatial audio for voice over")
        }

        if let mainEntity {
            mainEntity.addChild(voiceOverSource)
        }
        self.voiceOverAudioEntity = voiceOverSource
        os_log(.debug, "ITR..ADCOptimizedImmersive: ✅ Successfully set up voice over entity")
    }

    func attachPopSoundToTarget(_ target: Entity) {
        if let popSound = popAudioEntity {
            // Remove from current parent if any
            popSound.removeFromParent()
            
            // Add to new target and set transform
            target.addChild(popSound)
            popSound.transform = .init(scale: .one, rotation: .init(), translation: .zero)
            
            // Ensure spatial audio component is set
            if !popSound.components.has(SpatialAudioComponent.self) {
                popSound.components.set(SpatialAudioComponent(
                    gain: 1.0,
                    directivity: .beam(focus: 1.0)
                ))
                os_log(.debug, "ITR..attachPopSoundToTarget(): Added spatial audio component")
            }
            
            os_log(.debug, "ITR..attachPopSoundToTarget(): Successfully attached pop sound to target at position: \(target.position)")
        } else {
            os_log(.error, "ITR..attachPopSoundToTarget(): No pop sound entity available")
        }
    }

    func toggleVOAudioMode() {
        // Update the audio component
        if let voEntity = voiceOverAudioEntity {
            // Remove existing audio components using proper syntax
            voEntity.components[SpatialAudioComponent.self] = nil
            voEntity.components[ChannelAudioComponent.self] = nil
            
            // Toggle the property in the main class
            useChannelAudioForVO.toggle()
            
            // Add the appropriate component
            if useChannelAudioForVO {
                voEntity.components.set(ChannelAudioComponent(
                    gain: 0.0  // 0 dB = unity gain
                ))
                os_log(.debug, "ITR..toggleVOAudioMode: Switched to channel audio")
            } else {
                voEntity.components.set(SpatialAudioComponent(directivity: .beam(focus: 1.0)))
                os_log(.debug, "ITR..toggleVOAudioMode: Switched to spatial audio")
            }
        }
    }

    func playPopSound() {
        os_log(.debug, "ITR..playPopSound(): Starting pop sound playback...")
        
        if let controller = popAudioPlaybackController {
            if let popSound = popAudioEntity {
                os_log(.debug, "ITR..playPopSound(): Pop sound entity position: \(popSound.position)")
            }
            
            // Stop any currently playing pop sound
            controller.stop()
            
            // Play the sound
            controller.play()
            os_log(.debug, "ITR..playPopSound(): Started playing pop sound")
        } else {
            os_log(.error, "ITR..playPopSound(): ❌ No popAudioPlaybackController")
        }
    }

    @MainActor
    /// Plays voice over audio for the specified step.
    /// Uses channel-based audio if `useChannelAudioForVO` is true, 
    /// otherwise uses spatial audio.
    /// - Parameter step: The step index (0-3) to play voice over for
    func playVoiceOver(step: Int) async throws {
        os_log(.debug, "ITR..playVoiceOver(): Playing voice over for step \(step) (using channel audio: \(useChannelAudioForVO))")
        
        // Only check VO played state for steps 0-2
        if step != 3 {  // Skip check for step 3
            if step < dataModel.stepStates.count && dataModel.stepStates[step].voPlayed {
                return
            }
        }

        dataModel.isVOPlaying = true
        dataModel.voiceOverProgress = 0.0
        
        // Stop any currently playing VO
        if let controller = currentVOController {
            controller.stop()
            currentVOController = nil
        }
        
        // For step 3, play completion sound first
        if step == 3 {
            guard let completionAudio,
                  let niceJobAudio,
                  let vo4Audio,
                  let voEntity = voiceOverAudioEntity else {
                os_log(.error, "ITR..playVoiceOver(): Missing required audio or entity for step 3")
                throw NSError(domain: "ADCOptimizedImmersive", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing required audio or entity for step 3"])
            }
            
            // 1. Play completion sound and wait for it to finish
            await withCheckedContinuation { continuation in
                let completionController = voEntity.prepareAudio(completionAudio)
                completionController.completionHandler = {
                    os_log(.debug, "ITR..playVoiceOver(): Completion sound finished")
                    continuation.resume()
                }
                completionController.play()
                os_log(.debug, "ITR..playVoiceOver(): Started playing completion sound")
            }
            
            // 2. Play nice job audio and wait for it to finish
            await withCheckedContinuation { continuation in
                let niceJobController = voEntity.prepareAudio(niceJobAudio)
                niceJobController.completionHandler = {
                    os_log(.debug, "ITR..playVoiceOver(): Nice job audio finished")
                    continuation.resume()
                }
                niceJobController.play()
                os_log(.debug, "ITR..playVoiceOver(): Started playing nice job audio")
            }
            
            // 3. Play VO 4 with progress
            return await withCheckedContinuation { continuation in
                currentVOController = voEntity.prepareAudio(vo4Audio)
                currentVOController?.completionHandler = {
                    dataModel.voiceOverProgress = 0.0
                    dataModel.isVOPlaying = false
                    dataModel.markVOCompleted(for: step)  // Mark VO as completed
                    continuation.resume()
                }
                currentVOController?.play()
                
                // Start progress timer
                let duration = dataModel.voiceOverDurations[3] ?? 16.0
                Task {
                    let startTime = Date()
                    while dataModel.isVOPlaying {
                        let elapsed = Date().timeIntervalSince(startTime)
                        dataModel.voiceOverProgress = min(elapsed / duration, 1.0)
                        try? await Task.sleep(for: .milliseconds(16)) // ~60fps
                    }
                }
                
                os_log(.debug, "ITR..playVoiceOver(): Started playing VO 4")
            }
        }
        
        // Get appropriate VO resource for other steps
        let voResource: AudioFileResource? = switch step {
            case 0: vo1Audio
            case 1: vo2Audio
            case 2: vo3Audio
            default: nil
        }
        
        guard let voResource,
              let voEntity = voiceOverAudioEntity else {
            os_log(.error, "ITR..playVoiceOver(): Missing VO resource or entity for step \(step)")
            throw NSError(domain: "ADCOptimizedImmersive", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing VO resource or entity"])
        }
        
        // Create and play VO with completion handling
        return await withCheckedContinuation { continuation in
            currentVOController = voEntity.prepareAudio(voResource)
            currentVOController?.completionHandler = {
                dataModel.voiceOverProgress = 0.0
                dataModel.isVOPlaying = false
                dataModel.markVOCompleted(for: step)  // Mark VO as completed
                continuation.resume()
            }
            currentVOController?.play()
            
            // Start progress timer
            let duration = dataModel.voiceOverDurations[step] ?? 18.0
            Task {
                let startTime = Date()
                while dataModel.isVOPlaying {
                    let elapsed = Date().timeIntervalSince(startTime)
                    dataModel.voiceOverProgress = min(elapsed / duration, 1.0)
                    try? await Task.sleep(for: .milliseconds(16)) // ~60fps
                }
            }
            
            os_log(.debug, "ITR..playVoiceOver(): Started playing VO for step \(step)")
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
