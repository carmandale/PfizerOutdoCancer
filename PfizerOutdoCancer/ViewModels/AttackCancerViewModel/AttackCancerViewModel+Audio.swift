import SwiftUI
import RealityKitContent
import RealityKit

extension AttackCancerViewModel {
    // MARK: - Audio Setup
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
        
        // Create and set up audio entity with spatial audio
        let audioSource = Entity()
        audioSource.name = "EndGameToneSource"
        audioSource.position.z = 0.5
        Logger.audio("Created EndGameToneSource entity")
        
        audioSource.components.set(SpatialAudioComponent(
            gain: 1.0,
            directivity: .beam(focus: 1.0)
        ))
        Logger.audio("Added SpatialAudioComponent to EndGameToneSource")
        
        // Load audio resource
        do {
            Logger.audio("Attempting to load tone_cross_wav from Assets/Game/endGame.usda...")
            let resource = try await AudioFileResource(named: "/Root/tone_cross_wav", from: "Assets/Game/endGame.usda", in: realityKitContentBundle)
            Logger.audio("✅ Successfully loaded tone_cross_wav")
            
            // Store our resources
            self.endGameAudioSource = audioSource
            self.endGameAudioResource = resource
            
            // Attach to headTrackingRoot immediately
            headTrackingRoot.addChild(audioSource)
            Logger.audio("✅ Added EndGameToneSource to headTrackingRoot")
            
            // Pre-prepare the controller
            endGameAudioController = audioSource.prepareAudio(resource)
            if endGameAudioController != nil {
                Logger.audio("✅ Successfully prepared audio controller")
            } else {
                Logger.error("❌ Failed to prepare audio controller")
            }
            
            Logger.audio("✅ End game audio fully prepared")
        } catch {
            Logger.error("❌ Failed to load tone_cross_wav: \(error.localizedDescription)")
            Logger.error("Error details: \(error)")
        }
    }
    
    // MARK: - Audio Playback
    func playEndSound() async {
        Logger.audio("\n=== Playing end game sound ===\n")
        
        // Since everything is prepared, we just need to play
        if let controller = endGameAudioController {
            // Stop any existing playback first
            controller.stop()
            
            // Play the sound
            controller.play()
            Logger.audio("✅ Started playing end game tone")
        } else {
            Logger.error("❌ End game audio not prepared. Call prepareEndGameAudio first.")
        }
    }
}