import Foundation
import RealityKit
import SwiftUI
import Combine

/// Example class showing how to use the AudioSystem
/// This is for reference only and is not meant to be used directly
class AudioSystemExample {
    // Core properties
    private var audioSystem: AudioSystem?
    private var rootEntity: Entity?
    private var bundleReference: Bundle
    
    init(rootEntity: Entity?, bundle: Bundle = Bundle(for: RealityKitContent.self)) {
        self.rootEntity = rootEntity
        self.bundleReference = bundle
    }
    
    // MARK: - Setup Example
    
    /// Set up the audio system
    func setupAudio() {
        // Create audio system with debug visualization enabled
        audioSystem = AudioSystem(
            sceneContent: rootEntity,
            bundle: bundleReference,
            enableDebug: true
        )
        
        Logger.audio("Audio system initialized in example")
    }
    
    // MARK: - Resource Loading Example
    
    /// Load audio resources
    func loadAudioResources() async {
        guard let audioSystem = audioSystem else { return }
        
        // Load individual resources with error handling
        do {
            // Load heartbeat sound
            _ = try await audioSystem.loadResource(
                id: "heartbeat",
                path: "/Root/heartbeat_progressive_slow_to_fast_wav",
                assetFile: "Assets/Game/endGame.usda"
            )
            
            // Load magic zing sound
            _ = try await audioSystem.loadResource(
                id: "magic_zing",
                path: "/Root/magic_zing_wav",
                assetFile: "Assets/Game/endGame.usda"
            )
        } catch {
            Logger.audioError("Failed to load audio resources: \(error.localizedDescription)")
        }
        
        // Batch preload multiple resources
        await audioSystem.preloadResources([
            (id: "hope_restored", path: "/Root/Hope_Meter_Restored_wav", assetFile: "Assets/Game/endGame.usda"),
            (id: "tone_cross", path: "/Root/tone_cross_wav", assetFile: "Assets/Game/endGame.usda")
        ])
    }
    
    // MARK: - Creating Audio Sources Example
    
    /// Create audio sources
    func setupAudioSources(headTrackingRoot: Entity) {
        guard let audioSystem = audioSystem else { return }
        
        // Create a spatial audio source for ending sequence
        audioSystem.createSource(
            id: "endingSequence",
            parent: headTrackingRoot,
            position: SIMD3<Float>(0, 0, 0.75),  // Positioned in front of head
            type: .spatial,
            properties: SpatialAudioComponent(
                gain: 1.0,
                directivity: .beam(focus: 1.0)
            )
        )
        
        // Create an ambient audio source for background music
        audioSystem.createSource(
            id: "backgroundMusic",
            parent: rootEntity,
            type: .ambient,
            properties: SpatialAudioComponent(
                gain: -10.0,  // Lower volume for background
                directLevel: -5.0,
                reverbLevel: 0.0,
                directivity: .omni
            )
        )
        
        // Create a positional audio source attached to an object
        if let targetObject = rootEntity?.findEntity(named: "targetObject") {
            audioSystem.createSource(
                id: "objectSound",
                parent: targetObject,
                position: SIMD3<Float>(0, 0.1, 0),  // Small offset from object center
                type: .spatial,
                properties: SpatialAudioComponent(
                    gain: 0.0,
                    directivity: .beam(focus: 0.5)
                )
            )
        }
    }
    
    // MARK: - Playback Example
    
    /// Play a single sound
    func playSound() {
        guard let audioSystem = audioSystem else { return }
        
        // Play a single sound from a source
        audioSystem.playSound(
            resourceID: "magic_zing",
            sourceID: "endingSequence",
            loop: false,
            gain: nil  // Use the source's default gain
        )
    }
    
    /// Play a sound sequence
    func playEndingSequence() async {
        guard let audioSystem = audioSystem else { return }
        
        // Play a sequence of sounds with timing
        await audioSystem.playSequence(
            [
                ("heartbeat", 19.0),  // Play heartbeat, wait 19 seconds
                ("magic_zing", 0.0)   // Play magic_zing, no wait after
            ],
            sourceID: "endingSequence"
        )
    }
    
    /// Attach and play sound on an entity
    func playObjectInteractionSound(entity: Entity) {
        guard let audioSystem = audioSystem else { return }
        
        // Attach and play in one call
        let (sourceID, _) = audioSystem.attachAndPlay(
            resourceID: "tone_cross",
            to: entity,
            offset: SIMD3<Float>(0, 0.1, 0),
            loop: false,
            gain: 0.0,
            type: .spatial
        )
        
        // You can use the returned sourceID to stop the sound later
        // audioSystem.stopPlayback(sourceID: sourceID)
    }
    
    // MARK: - Audio Fade Examples
    
    /// Play background music with fade-in
    func playBackgroundMusicWithFade() async {
        guard let audioSystem = audioSystem else { return }
        
        // First ensure the source exists
        if audioSources(containsID: "backgroundMusic") == false {
            audioSystem.createSource(
                id: "backgroundMusic",
                parent: rootEntity,
                type: .ambient,
                properties: SpatialAudioComponent(gain: -100.0) // Start silent
            )
        }
        
        // Play the music (looped)
        audioSystem.playSound(
            resourceID: "hope_restored",
            sourceID: "backgroundMusic",
            loop: true
        )
        
        // Fade in over 3 seconds
        Logger.audio("Fading in background music over 3 seconds...")
        await audioSystem.fadeIn(
            sourceID: "backgroundMusic",
            targetGain: -10.0, // Not too loud
            duration: 3.0
        )
        Logger.audio("Background music fade-in complete")
    }
    
    /// Fade out and stop background music
    func stopBackgroundMusicWithFade() async {
        guard let audioSystem = audioSystem else { return }
        
        Logger.audio("Fading out background music over 2 seconds...")
        await audioSystem.fadeOut(
            sourceID: "backgroundMusic",
            duration: 2.0,
            stopAfterFade: true // Automatically stop after fade
        )
        Logger.audio("Background music fade-out complete")
    }
    
    /// Demonstrate fade to a specific level
    func adjustMusicVolumeWithFade() async {
        guard let audioSystem = audioSystem else { return }
        
        // Fade to a quieter level for dialog
        Logger.audio("Fading music to lower level for dialog...")
        await audioSystem.fade(
            sourceID: "backgroundMusic",
            to: -20.0, // Very quiet but still audible
            duration: 1.5
        )
        
        // Simulate dialog happening
        try? await Task.sleep(for: .seconds(5.0))
        
        // Fade back to normal level after dialog
        Logger.audio("Fading music back to normal level...")
        await audioSystem.fade(
            sourceID: "backgroundMusic",
            to: -10.0, // Normal background level
            duration: 1.5
        )
    }
    
    /// Demonstrate using the convenience method to attach with fade-in
    func playObjectAmbienceWithFade(entity: Entity) async {
        guard let audioSystem = audioSystem else { return }
        
        Logger.audio("Attaching and fading in ambience to object...")
        let (sourceID, _) = await audioSystem.attachAndFadeIn(
            resourceID: "heartbeat",
            to: entity,
            loop: true,
            gain: -5.0, // Final gain after fade
            type: .spatial,
            fadeDuration: 2.0
        )
        
        Logger.audio("Object ambience attached with ID: \(sourceID)")
    }
    
    // Helper method to check if a source exists
    private func audioSources(containsID id: String) -> Bool {
        guard let audioSystem = audioSystem else { return false }
        
        // We don't have direct access to audioSources dictionary, so we'll try to play a sound
        // and see if we get a warning in the logs. This is a workaround for the example.
        let controller = audioSystem.playSound(
            resourceID: "tone_cross", // Use any loaded resource
            sourceID: id,
            loop: false
        )
        
        // If we got a controller, the source exists; stop it immediately
        if let controller = controller {
            controller.stop()
            return true
        }
        
        return false
    }
    
    // MARK: - Audio Property Control Example
    
    /// Adjust spatial audio properties
    func adjustAudioProperties() {
        guard let audioSystem = audioSystem else { return }
        
        // Adjust gain (volume)
        audioSystem.setGain(-5.0, forSource: "backgroundMusic")
        
        // Change directivity pattern
        audioSystem.setDirectivity(.beam(focus: 0.7), forSource: "endingSequence")
        
        // Add reverb
        audioSystem.setReverb(.largeRoom, forSource: "objectSound")
        
        // Configure distance attenuation
        audioSystem.setDistanceAttenuation(.rolloff(factor: 0.5), forSource: "objectSound")
    }
    
    // MARK: - Debug Visualization Example
    
    /// Control debug visualization
    func toggleDebugVisuals() {
        guard let audioSystem = audioSystem else { return }
        
        // Toggle all debug visuals
        audioSystem.toggleDebugVisualization()
        
        // Toggle for specific source
        audioSystem.toggleDebugForSource(id: "endingSequence", enabled: true)
    }
    
    // MARK: - Cleanup Example
    
    /// Clean up audio resources
    func cleanupAudio() {
        guard let audioSystem = audioSystem else { return }
        
        // Stop specific playback
        audioSystem.stopPlayback(sourceID: "endingSequence")
        
        // Remove a specific source
        audioSystem.removeSource(id: "backgroundMusic")
        
        // Unload a resource
        audioSystem.unloadResource(id: "heartbeat")
        
        // Full system cleanup
        audioSystem.cleanup()
        audioSystem = nil
    }
} 