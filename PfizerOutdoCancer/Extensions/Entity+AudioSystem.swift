import Foundation
import RealityKit
import OSLog

// If using Apple's new Observation framework, uncomment the following import
// import Observation

/// A reusable audio system that can be attached to any RealityKit Entity.
/// It supports both spatial and channel-based audio playback, resource loading from RCP packages, and simple playback control.
@Observable
@MainActor  // Make the entire class MainActor-isolated
final class EntityAudioSystem: @unchecked Sendable {  // Make the class Sendable
    // MARK: - Properties
    let entity: Entity
    var spatialAudioEnabled: Bool
    var gain: Float
    var focus: Float

    /// New properties for spatial offset
    var positionOffset: SIMD3<Float> = .zero
    var rotationOffset: simd_quatf = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))  // Identity rotation

    /// Private anchor entity used for audio playback when spatial audio is enabled
    private var audioAnchor: Entity

    /// Dictionary to hold loaded audio resources keyed by their names.
    var loadedAudioResources: [String: AudioFileResource] = [:]

    /// Controller for the currently playing audio, if any.
    var currentAudioPlayback: AudioPlaybackController?
    var currentAudioName: String?

    var isPlaying: Bool = false
    var playbackProgress: Double = 0.0

    // MARK: - Initialization
    init(entity: Entity, spatialAudioEnabled: Bool = true, gain: Float = 1.0, focus: Float = 1.0) {
        self.entity = entity
        self.spatialAudioEnabled = spatialAudioEnabled
        self.gain = gain
        self.focus = focus

        // Create a child anchor entity for audio playback
        self.audioAnchor = Entity()
        // Set initial transform using positionOffset and rotationOffset, using the order: scale, rotation, translation
        self.audioAnchor.transform = Transform(scale: .one, rotation: rotationOffset, translation: positionOffset)
        // Add the audioAnchor as a child of the main entity
        entity.addChild(audioAnchor)

        // If spatial audio is enabled, add a SpatialAudioComponent to the audioAnchor if not already present.
        if spatialAudioEnabled, !audioAnchor.components.has(SpatialAudioComponent.self) {
            audioAnchor.components.set(SpatialAudioComponent(
                gain: Double(gain),
                directivity: .beam(focus: Double(focus))
            ))
        }
    }

    // MARK: - Audio Resource Loading
    /// Loads an audio resource from the specified source and bundle.
    /// - Parameters:
    ///   - audioName: The name of the audio file (e.g. "bubblepop_mp3").
    ///   - source: The asset source, which can be a scene name (e.g. "antibodyScene.usda") or folder name in the RCP package.
    ///   - bundle: The bundle containing the audio asset.
    ///
    /// The resource is stored keyed by `audioName`.
    func loadAudio(named audioName: String, from source: String, in bundle: Bundle) async throws {
        let resource = try await AudioFileResource(named: "/Root/\(audioName)", from: source, in: bundle)
        loadedAudioResources[audioName] = resource
        Logger.audio("Loaded audio resource: \(audioName)")
    }

    // MARK: - Playback Control
    /// Plays the audio corresponding to `audioName`.
    /// If another audio is already playing, it is stopped first.
    /// - Parameters:
    ///   - audioName: The key for the loaded audio resource.
    ///   - duration: Optional duration for playback progress tracking (defaults to 5 seconds if not provided).
    func play(audioNamed audioName: String, duration: Double? = nil) async throws {
        guard let resource = loadedAudioResources[audioName] else {
            throw NSError(domain: "EntityAudioSystem", code: -1, userInfo: [NSLocalizedDescriptionKey: "Audio resource \(audioName) not loaded"])
        }

        Logger.audio("Resource for \(audioName) found: \(resource)")

        // Stop current audio if playing
        if isPlaying {
            stop()
        }

        Logger.audio("Preparing playback controller for \(audioName)")
        // Prepare audio using the audioAnchor's prepareAudio method
        let playbackController = audioAnchor.prepareAudio(resource)
        currentAudioPlayback = playbackController
        currentAudioName = audioName
        isPlaying = true
        playbackProgress = 0.0

        // Create a weak reference to self for the completion handler
        weak var weakSelf = self
        
        // Set completion handler on main actor
        playbackController.completionHandler = {
            Task { @MainActor in
                guard let self = weakSelf else { return }
                Logger.audio("Audio \(audioName) completed playback")
                self.isPlaying = false
                self.playbackProgress = 1.0
                self.currentAudioPlayback = nil
            }
        }

        Logger.audio("Calling playbackController.play() for \(audioName)")
        playbackController.play()
        Logger.audio("Called playbackController.play() for \(audioName)")

        // Track playback progress if a duration is provided
        let totalDuration = duration ?? 5.0
        let startTime = Date()
        
        // Create a separate Task for progress tracking
        Task { @MainActor in
            guard let self = weakSelf else { return }
            while self.isPlaying {
                let elapsed = Date().timeIntervalSince(startTime)
                // Log progress every second approximately
                if Int(elapsed) % 1 == 0 {
                    Logger.audio("Playback progress for \(audioName): \(self.playbackProgress * 100)% after \(Int(elapsed))s")
                }
                self.playbackProgress = min(elapsed / totalDuration, 1.0)
                try? await Task.sleep(nanoseconds: 16_000_000) // ~60fps
            }
        }
    }

    /// Stops the current audio playback if any.
    func stop() {
        if let controller = currentAudioPlayback, isPlaying {
            controller.stop()
            isPlaying = false
            playbackProgress = 0.0
            currentAudioPlayback = nil
            Logger.audio("Stopped audio playback")
        }
    }

    // MARK: - Configuration Updates
    /// Updates the gain value used for spatial audio. This will affect future playback.
    func updateGain(newGain: Float) {
        gain = newGain
        Logger.audio("Updated gain to \(newGain)")
        if spatialAudioEnabled {
            if audioAnchor.components.has(SpatialAudioComponent.self) {
                audioAnchor.components.remove(SpatialAudioComponent.self)
                audioAnchor.components.set(SpatialAudioComponent(
                    gain: Double(newGain),
                    directivity: .beam(focus: Double(focus))
                ))
                Logger.audio("Reattached SpatialAudioComponent with updated gain")
            }
        }
    }

    /// Updates the focus value (directivity) for spatial audio. This will affect future playback.
    func updateFocus(newFocus: Float) {
        focus = newFocus
        Logger.audio("Updated focus to \(newFocus)")
        if spatialAudioEnabled {
            if audioAnchor.components.has(SpatialAudioComponent.self) {
                audioAnchor.components.remove(SpatialAudioComponent.self)
                audioAnchor.components.set(SpatialAudioComponent(
                    gain: Double(gain),
                    directivity: .beam(focus: Double(newFocus))
                ))
                Logger.audio("Reattached SpatialAudioComponent with updated focus")
            }
        }
    }

    /// Updates the position offset for the audio playback. This adjusts the local position of the audio anchor.
    func updatePositionOffset(newOffset: SIMD3<Float>) {
        positionOffset = newOffset
        updateAudioAnchorTransform()
        Logger.audio("Updated audio position offset to \(newOffset)")
    }

    /// Updates the rotation offset for the audio playback. This adjusts the local rotation of the audio anchor.
    func updateRotationOffset(newRotation: simd_quatf) {
        rotationOffset = newRotation
        updateAudioAnchorTransform()
        Logger.audio("Updated audio rotation offset")
    }

    /// Helper method to update the audioAnchor's transform with the current offset and rotation.
    private func updateAudioAnchorTransform() {
        audioAnchor.transform = Transform(scale: .one, rotation: rotationOffset, translation: positionOffset)
    }

    // MARK: - Cleanup
    /// Stops any ongoing audio and clears loaded resources. Also removes any spatial audio components and the audio anchor added by this system.
    func cleanup() {
        stop()
        loadedAudioResources.removeAll()
        if spatialAudioEnabled, audioAnchor.components.has(SpatialAudioComponent.self) {
            audioAnchor.components.remove(SpatialAudioComponent.self)
        }
        audioAnchor.removeFromParent()
        Logger.audio("Audio system cleanup completed")
    }
}

// MARK: - Entity Extension
extension Entity {
    /// Attaches a new EntityAudioSystem to the entity.
    /// - Parameters:
    ///   - spatial: Enables spatial audio if true. Defaults to true.
    ///   - gain: Initial gain value for spatial audio. Defaults to 1.0.
    ///   - focus: Initial focus value for spatial audio. Defaults to 1.0.
    /// - Returns: A new instance of EntityAudioSystem configured with the provided parameters.
    func attachAudioSystem(spatial: Bool = true, gain: Float = 1.0, focus: Float = 1.0) -> EntityAudioSystem {
        return EntityAudioSystem(entity: self, spatialAudioEnabled: spatial, gain: gain, focus: focus)
    }
} 
