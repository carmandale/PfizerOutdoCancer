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
    
    /// Initializes the new AudioSystem and prepares it for use
    /// Call this during environment setup
    func initializeAndPrepareAudioSystem() async {
        Logger.audio("\n=== Initializing new AudioSystem ===\n")
        
        // Skip if already initialized
        guard !isAudioSystemInitialized, let rootEntity = rootEntity else {
            Logger.audioWarning("Cannot initialize AudioSystem: rootEntity missing or already initialized")
            return
        }
        
        // Create the audio system
        audioSystem = AudioSystem(
            sceneContent: rootEntity,
            bundle: realityKitContentBundle,
            enableDebug: isAudioDebugVisible
        )
        
        isAudioSystemInitialized = true
        Logger.audio("✅ AudioSystem initialized")
        
        // Load resources
        await loadAudioResourcesWithNewSystem()
        
        // Set up sources
        setupAudioSourcesWithNewSystem()
        
        Logger.audio("✅ Audio system fully prepared and ready for use")
    }
    
    /// Loads all audio resources using the new audio system
    private func loadAudioResourcesWithNewSystem() async {
        guard let audioSystem = audioSystem else { return }
        
        Logger.audio("Loading audio resources with new AudioSystem...")
        
        do {
            // Load tone_cross
            _ = try await audioSystem.loadResource(
                id: "tone_cross",
                path: "/Root/tone_cross_wav",
                assetFile: "Assets/Game/endGame.usda"
            )
            
            // Load heartbeat
            _ = try await audioSystem.loadResource(
                id: "heartbeat",
                path: "/Root/heartbeat_progressive_slow_to_fast_wav",
                assetFile: "Assets/Game/endGame.usda"
            )
            
            // Load smashed
            _ = try await audioSystem.loadResource(
                id: "smashed",
                path: "/Root/smashed_wav",
                assetFile: "Assets/Game/endGame.usda"
            )
            
            // Load magic_zing
            _ = try await audioSystem.loadResource(
                id: "magic_zing",
                path: "/Root/magic_zing_wav",
                assetFile: "Assets/Game/endGame.usda"
            )
            
            // Load hope meter restored
            _ = try await audioSystem.loadResource(
                id: "hope_restored",
                path: "/Root/Hope_Meter_Restored_wav",
                assetFile: "Assets/Game/endGame.usda"
            )
            
            // Load great job
            _ = try await audioSystem.loadResource(
                id: "great_job",
                path: "/Root/GreatJob_mp3",
                assetFile: "PressStart_VO.usda"
            )
            
            Logger.audio("✅ All audio resources loaded with new system")
        } catch {
            Logger.audioError("Failed to load audio resources with new system: \(error.localizedDescription)")
        }
    }
    
    /// Sets up audio sources using the new audio system
    private func setupAudioSourcesWithNewSystem() {
        guard let audioSystem = audioSystem, let root = rootEntity else { return }
        
        Logger.audio("Setting up audio sources with new AudioSystem...")
        
        // Find head tracking entity for spatial audio positioned relative to user
        if let headTrackingRoot = root.findEntity(named: "headTrackingRoot") {
            // Create ending sequence source (directional, in front of user)
            audioSystem.createSource(
                id: "endingSequence",
                parent: headTrackingRoot,
                position: SIMD3<Float>(0, 0, 0.75),
                type: .spatial,
                properties: SpatialAudioComponent(
                    gain: 1.0,
                    directivity: .beam(focus: 1.0)
                )
            )
            
            // Create victory sequence source
            audioSystem.createSource(
                id: "victorySequence",
                parent: headTrackingRoot,
                position: SIMD3<Float>(0, 0, 0.75),
                type: .spatial,
                properties: SpatialAudioComponent(
                    gain: 1.0,
                    directivity: .beam(focus: 1.0)
                )
            )
            
            // Create great job sequence source
            audioSystem.createSource(
                id: "greatJob",
                parent: headTrackingRoot,
                position: SIMD3<Float>(0, 0, 0.75),
                type: .spatial,
                properties: SpatialAudioComponent(
                    gain: 0.0,
                    directLevel: 0.0,
                    reverbLevel: -7.1,
                    directivity: .beam(focus: 0.3),
                    distanceAttenuation: .rolloff(factor: 0.5)
                )
            )
            
            Logger.audio("✅ Created audio sources for spatial sequences")
        }
        
        // Create ambient sources attached to root
        audioSystem.createSource(
            id: "backgroundAmbience",
            parent: root,
            type: .ambient,
            properties: SpatialAudioComponent(gain: -10.0)
        )
        
        Logger.audio("✅ All audio sources set up with new system")
    }
    
    /// Toggles the visibility of the audio debug cone
    func toggleAudioDebugVisuals() {
        isAudioDebugVisible.toggle()
        
        if useNewAudioSystem {
            // Use new audio system to toggle debug visuals
            audioSystem?.toggleDebugVisualization(enabled: isAudioDebugVisible)
        } else {
            // Legacy approach
            audioDebugCone?.isEnabled = isAudioDebugVisible
        }
        
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
        if useNewAudioSystem {
            // Use the new audio system approach
            await initializeAndPrepareAudioSystem()
            return
        }
        
        // Legacy implementation continues below
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
            let greatJobResource = try await AudioFileResource(named: "/Root/GreatJob_mp3", from: "PressStart_VO.usda", in: realityKitContentBundle)
            loadedAudioResources["great_job"] = greatJobResource
            Logger.audio("✅ Successfully loaded great_job")
            
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
        if useNewAudioSystem {
            await playVictorySequenceWithNewSystem()
            return
        }
        
        await playAudioSequence([
            ("hope_restored", 2.0),
            ("tone_cross", 0.0)
        ], type: .victory)
    }
    
    /// Play heartbeat, wait 19 seconds, then play magic_zing
    func playEndingSequence() async {
        if useNewAudioSystem {
            await playEndingSequenceWithNewSystem()
            return
        }
        
        await playAudioSequence([
            ("heartbeat", 19.0),
            ("magic_zing", 0.0)
        ], type: .ending)
    }
    
    /// Play the great job voice over
    func playGreatJob() async {
        // Skip if already played
        if hasPlayedGreatJob {
            Logger.audio("Great job already played, skipping")
            return
        }

        if useNewAudioSystem {
            await playGreatJobWithNewSystem()
            return
        }
        
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
    
    // MARK: - New Audio System Playback Methods
    
    /// Play ending sequence using new audio system
    func playEndingSequenceWithNewSystem() async {
        // Skip if already played
        if hasPlayedEndingSequence {
            Logger.audio("Ending sequence already played, skipping")
            return
        }
        
        guard let audioSystem = audioSystem else {
            Logger.audioWarning("Cannot play ending sequence - AudioSystem not initialized")
            return
        }
        
        Logger.audio("\n=== Playing ending sequence with new audio system ===\n")
        
        // Play the sequence
        await audioSystem.playSequence(
            [
                ("heartbeat", 19.0),
                ("magic_zing", 0.0)
            ],
            sourceID: "endingSequence"
        )
        
        // Mark as played
        hasPlayedEndingSequence = true
        Logger.audio("✅ Ending sequence completed with new system")
    }
    
    /// Play victory sequence using new audio system
    func playVictorySequenceWithNewSystem() async {
        // Skip if already played
        if hasPlayedVictorySequence {
            Logger.audio("Victory sequence already played, skipping")
            return
        }
        
        guard let audioSystem = audioSystem else {
            Logger.audioWarning("Cannot play victory sequence - AudioSystem not initialized")
            return
        }
        
        Logger.audio("\n=== Playing victory sequence with new audio system ===\n")
        
        // Play the sequence
        await audioSystem.playSequence(
            [
                ("hope_restored", 2.0),
                ("tone_cross", 0.0)
            ],
            sourceID: "victorySequence"
        )
        
        // Mark as played
        hasPlayedVictorySequence = true
        Logger.audio("✅ Victory sequence completed with new system")
    }
    
    /// Play great job voice over using new audio system
    func playGreatJobWithNewSystem() async {
        // Skip if already played
        if hasPlayedGreatJob {
            Logger.audio("Great job already played, skipping")
            return
        }
        
        guard let audioSystem = audioSystem else {
            Logger.audioWarning("Cannot play great job - AudioSystem not initialized")
            return
        }
        
        Logger.audio("\n=== Playing great job with new audio system ===\n")
        
        // Play the sound
        audioSystem.playSound(
            resourceID: "great_job",
            sourceID: "greatJob",
            loop: false
        )
        
        // Mark as played
        hasPlayedGreatJob = true
        Logger.audio("✅ Great job started with new system")
    }
    
    // MARK: - Audio System Control
    
    /// Enables the new audio system and disables the legacy implementation
    /// Call this to switch to the new system
    func enableNewAudioSystem() async {
        // Skip if already using the new system
        if useNewAudioSystem {
            Logger.audio("New audio system already enabled")
            return
        }
        
        Logger.audio("\n=== Switching to new audio system ===\n")
        
        // Ensure new system is initialized first
        if !isAudioSystemInitialized {
            await initializeAndPrepareAudioSystem()
        }
        
        // Stop any playback from legacy system
        endingSequenceController?.stop()
        victorySequenceController?.stop()
        greatJobController?.stop()
        
        // Set flag to use new system
        useNewAudioSystem = true
        Logger.audio("✅ Now using new audio system for all audio playback")
    }
    
    /// Updates or creates the appropriate methods to use the selected audio system
    func updateSequencePlaybackMethods() {
        // Update playEndingSequence
        let originalPlayEndingSequence = playEndingSequence
        playEndingSequence = {
            if self.useNewAudioSystem {
                await self.playEndingSequenceWithNewSystem()
            } else {
                await originalPlayEndingSequence()
            }
        }
        
        // Update playVictorySequence
        let originalPlayVictorySequence = playVictorySequence
        playVictorySequence = {
            if self.useNewAudioSystem {
                await self.playVictorySequenceWithNewSystem()
            } else {
                await originalPlayVictorySequence()
            }
        }
        
        // playGreatJob is already updated with the conditional check
    }
}