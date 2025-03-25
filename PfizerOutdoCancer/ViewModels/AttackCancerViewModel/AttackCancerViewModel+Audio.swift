import SwiftUI
import RealityKitContent
import RealityKit

// MARK: - Audio Sequence Types
enum AudioSequenceType {
    case ending
    case victory
}

extension AttackCancerViewModel {
    // MARK: - Audio Setup
    
    /// Toggles the visibility of the audio debug cone
    func toggleAudioDebugVisuals() {
        isAudioDebugVisible.toggle()
        audioDebugCone?.isEnabled = isAudioDebugVisible
        Logger.audio("Audio debug visuals: \(isAudioDebugVisible ? "shown" : "hidden")")
    }
    
    /// Creates a debug cone to visualize the audio source direction
    func createAudioDebugCone() -> ModelEntity {
        // Create a cone mesh with specified dimensions
        let cone = MeshResource.generateCone(height: 0.2, radius: 0.1)
        
        // Create a red material
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .red, texture: nil)
        material.roughness = 0.8
        material.metallic = 0.0
        
        // Create the model entity
        let debugCone = ModelEntity(mesh: cone, materials: [material])
        
        // Set transform
        debugCone.transform = Transform(
            scale: .one,
            rotation: simd_quatf(angle: .pi / 2, axis: [1, 0, 0]) * // -90 degrees around X
                     simd_quatf(angle: .pi, axis: [0, 1, 0]),      // 180 degrees around Y
            translation: [0, 0, -0.1]
        )
        
        // Initially disabled
        debugCone.isEnabled = false
        
        return debugCone
    }
    
    func prepareEndGameAudio() async {
        Logger.audio("\n=== Preparing end game audio ===\n")
        
        // First verify we can find our root entities
        guard let root = appModel.gameState.rootEntity else {
            Logger.error("❌ Cannot prepare end game audio - root entity not found")
            return
        }
        Logger.audio("✅ Found root entity: \(root.name)")
        
        guard let headTrackingRoot = root.findEntity(named: "headTrackingRoot") else {
            Logger.error("❌ Cannot prepare end game audio - headTrackingRoot not found")
            return
        }
        Logger.audio("✅ Found headTrackingRoot at position: \(headTrackingRoot.position)")
        
        // Create ending sequence source
        let endingSource = Entity()
        endingSource.name = "EndingSequenceSource"
        endingSource.position = SIMD3<Float>(0, 0, 0.75)
        endingSource.components.set(SpatialAudioComponent(gain: 1.0, directivity: .beam(focus: 1.0)))
        
        // Create and add debug cone for ending sequence
        let endingDebugCone = createAudioDebugCone()
        endingSource.addChild(endingDebugCone)
        self.audioDebugCone = endingDebugCone
        Logger.audio("Added debug cone to ending sequence source")
        
        headTrackingRoot.addChild(endingSource)
        self.endingSequenceAudioSource = endingSource
        Logger.audio("✅ Created ending sequence source")
        
        // Create victory sequence source
        let victorySource = Entity()
        victorySource.name = "VictorySequenceSource"
        victorySource.position = SIMD3<Float>(0, 0, 0.75)  // Centered
        victorySource.components.set(SpatialAudioComponent(gain: 1.0, directivity: .beam(focus: 1.0)))
        headTrackingRoot.addChild(victorySource)
        self.victorySequenceAudioSource = victorySource
        Logger.audio("✅ Created victory sequence source")
        
        // Create great job sequence source
        let greatJobSource = Entity()
        greatJobSource.name = "GreatJobSequenceSource"
        greatJobSource.position = SIMD3<Float>(0, 0, 0.75)
        greatJobSource.components.set(SpatialAudioComponent(
            gain: .init(0.0),           // 0.0 dB
            directLevel: .init(0.0),    // 0.0 dB
            reverbLevel: .init(-7.1),   // -7.1 dB
            directivity: .beam(focus: 0.3),
            distanceAttenuation: .rolloff(factor: 0.5)  // Rolloff Factor: 0.5
        ))
        headTrackingRoot.addChild(greatJobSource)
        self.greatJobAudioSource = greatJobSource
        Logger.audio("✅ Created great job sequence source")
        
        // Create alert sequence source with same settings as great job
        let alertSource = Entity()
        alertSource.name = "AlertSequenceSource"
        alertSource.position = SIMD3<Float>(0, 0, 0.75)
        alertSource.components.set(SpatialAudioComponent(
            gain: .init(-20.0),           // -20.0 dB
            directLevel: .init(0.0),    // 0.0 dB
            reverbLevel: .init(-7.1),   // -7.1 dB
            directivity: .beam(focus: 0.3),
            distanceAttenuation: .rolloff(factor: 1.0)  // Rolloff Factor: 0.5
        ))
        headTrackingRoot.addChild(alertSource)
        self.alertAudioSource = alertSource
        Logger.audio("✅ Created alert sequence source")
        
        // Load all audio resources
        do {
            // Load tone_cross
            Logger.audio("Attempting to load tone_cross_wav...")
            let toneCrossResource = try await AudioFileResource(named: "/Root/tone_cross_wav", from: "Assets/Game/endGame.usda", in: realityKitContentBundle)
            loadedAudioResources["tone_cross"] = toneCrossResource
            Logger.audio("✅ Successfully loaded tone_cross")
            
            // Load heartbeat
            let heartbeatResource = try await AudioFileResource(named: "/Root/heartbeat_progressive_slow_to_fast_wav", from: "Assets/Game/endGame.usda", in: realityKitContentBundle)
            loadedAudioResources["heartbeat"] = heartbeatResource
            Logger.audio("✅ Successfully loaded heartbeat")
            
            // Load smashed
            let smashedResource = try await AudioFileResource(named: "/Root/smashed_wav", from: "Assets/Game/endGame.usda", in: realityKitContentBundle)
            loadedAudioResources["smashed"] = smashedResource
            Logger.audio("✅ Successfully loaded smashed")
            
            // Load magic_zing
            let magicZingResource = try await AudioFileResource(named: "/Root/magic_zing_wav", from: "Assets/Game/endGame.usda", in: realityKitContentBundle)
            loadedAudioResources["magic_zing"] = magicZingResource
            Logger.audio("✅ Successfully loaded magic_zing")
            
            // Load hope meter restored
            let hopeRestoredResource = try await AudioFileResource(named: "/Root/Hope_Meter_Restored_wav", from: "Assets/Game/endGame.usda", in: realityKitContentBundle)
            loadedAudioResources["hope_restored"] = hopeRestoredResource
            Logger.audio("✅ Successfully loaded hope_restored")
            
            // Load great job
            let greatJobResource = try await AudioFileResource(named: "/Root/v07_785793_great_job_wav", from: "PressStart_VO.usda", in: realityKitContentBundle)
            loadedAudioResources["great_job"] = greatJobResource
            Logger.audio("✅ Successfully loaded great_job")
            
            // Load alert sound
            let alertResource = try await AudioFileResource(named: "/Root/alert_wav", from: "PressStart_VO.usda", in: realityKitContentBundle)
            loadedAudioResources["alert"] = alertResource
            Logger.audio("✅ Successfully loaded alert")
            
            Logger.audio("✅ End game audio fully prepared with \(loadedAudioResources.count) sounds")
        } catch {
            Logger.error("❌ Failed to load audio resources: \(error.localizedDescription)")
            Logger.error("Error details: \(error)")
        }
    }
    
    // MARK: - Audio Playback
    func playEndSound(_ soundName: String, forSequence sequenceType: AudioSequenceType) async {
        Logger.audio("\n=== Playing sound: \(soundName) for sequence: \(sequenceType) ===\n")
        
        let (audioSource, controller) = switch sequenceType {
        case .ending:
            (endingSequenceAudioSource, endingSequenceController)
        case .victory:
            (victorySequenceAudioSource, victorySequenceController)
        }
        
        guard let source = audioSource,
              let resource = loadedAudioResources[soundName] else {
            Logger.error("❌ Required resources not found for \(soundName)")
            return
        }
        
        // Stop current controller if it exists
        controller?.stop()
        
        // Create new controller and store it
        let newController = source.prepareAudio(resource)
        newController.play()
        
        // Store the controller in the appropriate property
        switch sequenceType {
        case .ending:
            endingSequenceController = newController
        case .victory:
            victorySequenceController = newController
        }
        
        Logger.audio("✅ Started playing \(soundName) for \(sequenceType)")
    }
    
    /// Plays a sequence of audio elements with specified pauses between them
    /// - Parameters:
    ///   - sequence: Array of tuples containing the sound name and the pause duration
    ///   - type: The type of sequence being played (ending or victory)
    func playAudioSequence(_ sequence: [(sound: String, pauseAfter: TimeInterval)], type: AudioSequenceType) async {
        Logger.audio("\n=== Starting \(type) sequence with \(sequence.count) elements ===\n")
        
        for (index, element) in sequence.enumerated() {
            await playEndSound(element.sound, forSequence: type)
            
            if element.pauseAfter > 0 {
                Logger.audio("Pausing for \(element.pauseAfter) seconds after sound \(element.sound)")
                try? await Task.sleep(for: .seconds(element.pauseAfter))
            }
            
            Logger.audio("Completed playing sequence element \(index + 1)/\(sequence.count)")
        }
        
        Logger.audio("✅ Audio sequence completed")
    }
    
    /// Play hope_restored, wait 2 seconds, then play tone_cross
    func playVictorySequence() async {
        await playAudioSequence([
            ("hope_restored", 2.0),
            ("tone_cross", 0.0)
        ], type: .victory)
    }
    
    /// Play heartbeat, wait 19 seconds, then play magic_zing
    func playEndingSequence() async {
        await playAudioSequence([
            ("heartbeat", 19.0),
            ("magic_zing", 0.0)
        ], type: .ending)
    }
    
    /// Play the great job voice over
    func playGreatJob() async {
        Logger.audio("\n=== Playing Great Job VO ===\n")
        
        // Stop any existing playback
        greatJobController?.stop()
        
        guard let source = greatJobAudioSource,
              let resource = loadedAudioResources["great_job"] else {
            Logger.error("❌ Required resources not found for great_job")
            return
        }
        
        // Create new controller and store it
        let newController = source.prepareAudio(resource)
        newController.play()
        greatJobController = newController
        hasPlayedGreatJob = true
        
        Logger.audio("✅ Started playing great_job")
    }
    
    /// Play the alert sound when tutorial becomes visible
    func playAlert() async {
        Logger.audio("\n=== Playing Alert Sound ===\n")
        
        // Stop any existing playback
        alertController?.stop()
        
        guard let source = alertAudioSource,
              let resource = loadedAudioResources["alert"] else {
            Logger.error("❌ Required resources not found for alert")
            return
        }
        
        // Create new controller and store it
        let newController = source.prepareAudio(resource)
        newController.play()
        alertController = newController
        
        Logger.audio("✅ Started playing alert sound")
    }
}
