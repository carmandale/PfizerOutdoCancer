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