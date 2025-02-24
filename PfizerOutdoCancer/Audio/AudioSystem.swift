import Foundation
import RealityKit
import SwiftUI
import Combine

/// A reusable system for managing spatial audio in visionOS
/// Uses the modern @Observable pattern for efficient SwiftUI integration
@Observable
class AudioSystem {
    // MARK: - Properties
    
    /// Root entity in the scene for adding sources without a parent
    private var sceneContent: Entity?
    
    /// Bundle containing audio resources
    private var contentBundle: Bundle
    
    /// Dictionary of audio sources by ID
    private var audioSources: [String: AudioSource] = [:]
    
    /// Cache of loaded audio resources
    private var resourceCache: [String: AudioFileResource] = [:]
    
    /// Whether debug visualization is enabled globally
    private var isDebugEnabled: Bool = false
    
    /// Combine subscriptions
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initialize with scene reference and bundle
    /// - Parameters:
    ///   - sceneContent: Root entity for the scene
    ///   - bundle: Bundle containing audio resources (default: .main)
    ///   - enableDebug: Whether to enable debug visualization by default
    init(sceneContent: Entity?, bundle: Bundle = .main, enableDebug: Bool = false) {
        self.sceneContent = sceneContent
        self.contentBundle = bundle
        self.isDebugEnabled = enableDebug
        
        Logger.audio("AudioSystem initialized with \(enableDebug ? "enabled" : "disabled") debug visualization")
    }
    
    // MARK: - Source Management
    
    /// Create a new audio source with the specified properties
    /// - Parameters:
    ///   - id: Unique identifier for the source
    ///   - parent: Optional parent entity (uses sceneContent if nil)
    ///   - position: Position relative to parent
    ///   - rotation: Rotation relative to parent
    ///   - type: Type of audio source
    ///   - properties: Optional spatial audio properties
    /// - Returns: ID of the created source
    func createSource(
        id: String,
        parent: Entity? = nil,
        position: SIMD3<Float> = .zero,
        rotation: simd_quatf = .init(),
        type: AudioType = .spatial,
        properties: SpatialAudioComponent? = nil
    ) -> String {
        Logger.audio("Creating audio source: \(id)")
        
        // Remove existing source with this ID if it exists
        if audioSources[id] != nil {
            removeSource(id: id)
        }
        
        // Create the entity for this audio source
        let sourceEntity = Entity()
        sourceEntity.name = "AudioSource_\(id)"
        
        // Set position and rotation
        sourceEntity.position = position
        sourceEntity.orientation = rotation
        
        // Configure spatial audio component based on type
        switch type {
        case .spatial:
            // Use provided properties or default
            sourceEntity.spatialAudio = properties ?? SpatialAudioComponent(gain: 0.0)
        case .ambient:
            // Ambient audio has no directivity and full reverb
            sourceEntity.spatialAudio = properties ?? SpatialAudioComponent(
                gain: 0.0,
                directLevel: -5.0,
                reverbLevel: 0.0,
                directivity: .omni
            )
        case .channel:
            // Channel audio is basic audio without spatial properties
            sourceEntity.spatialAudio = properties ?? SpatialAudioComponent(
                gain: 0.0,
                directivity: .omni
            )
        }
        
        // Add to parent entity
        if let parent = parent {
            parent.addChild(sourceEntity)
            
            // Store the source
            let source = AudioSource(
                entity: sourceEntity,
                type: type,
                parentEntity: parent,
                positionOffset: position,
                rotationOffset: rotation
            )
            audioSources[id] = source
            
            Logger.audio("Added audio source '\(id)' to parent '\(parent.name)'")
        } else if let scene = sceneContent {
            scene.addChild(sourceEntity)
            
            // Store the source
            let source = AudioSource(
                entity: sourceEntity,
                type: type,
                parentEntity: scene,
                positionOffset: position,
                rotationOffset: rotation
            )
            audioSources[id] = source
            
            Logger.audio("Added audio source '\(id)' to scene root")
        } else {
            Logger.audioWarning("No parent or scene content available for audio source '\(id)'")
            
            // Store the source anyway, but it won't be in the scene yet
            let source = AudioSource(
                entity: sourceEntity,
                type: type
            )
            audioSources[id] = source
        }
        
        // Add debug visualization if enabled
        if isDebugEnabled, type == .spatial {
            if let source = audioSources[id] {
                let debugVisual = createDebugVisual(for: source)
                sourceEntity.addChild(debugVisual)
                
                // Update our stored source with the debug visual
                var updatedSource = source
                updatedSource.debugVisual = debugVisual
                audioSources[id] = updatedSource
                
                Logger.audio("Added debug visualization to source '\(id)'")
            }
        }
        
        return id
    }
    
    /// Remove an audio source and its resources
    /// - Parameter id: ID of the source to remove
    func removeSource(id: String) {
        guard let source = audioSources[id] else {
            Logger.audioWarning("Attempted to remove non-existent audio source: \(id)")
            return
        }
        
        Logger.audio("Removing audio source: \(id)")
        
        // Stop all active controllers
        for controller in source.controllers {
            controller.stop()
        }
        
        // Remove the entity from its parent
        source.entity.removeFromParent()
        
        // Remove from our dictionary
        audioSources.removeValue(forKey: id)
    }
    
    /// Update the position of an existing source
    /// - Parameters:
    ///   - id: ID of the source to update
    ///   - position: New position
    func updateSourcePosition(id: String, position: SIMD3<Float>) {
        guard var source = audioSources[id] else {
            Logger.audioWarning("Attempted to update position of non-existent audio source: \(id)")
            return
        }
        
        Logger.audio("Updating position of audio source '\(id)' to \(position)")
        
        // Update the entity position
        source.entity.position = position
        
        // Update the position offset if attached to a parent
        if source.parentEntity != nil {
            source.positionOffset = position
        }
        
        // Update our dictionary
        audioSources[id] = source
    }
    
    /// Update the rotation of an existing source
    /// - Parameters:
    ///   - id: ID of the source to update
    ///   - rotation: New rotation
    func updateSourceRotation(id: String, rotation: simd_quatf) {
        guard var source = audioSources[id] else {
            Logger.audioWarning("Attempted to update rotation of non-existent audio source: \(id)")
            return
        }
        
        Logger.audio("Updating rotation of audio source '\(id)'")
        
        // Update the entity rotation
        source.entity.orientation = rotation
        
        // Update the rotation offset if attached to a parent
        if source.parentEntity != nil {
            source.rotationOffset = rotation
        }
        
        // Update our dictionary
        audioSources[id] = source
    }
    
    // MARK: - Resource Management
    
    /// Load an audio resource from a file
    /// - Parameters:
    ///   - id: ID for the resource
    ///   - path: Path to the audio file within the USDA
    ///   - assetFile: USDA file containing the audio
    /// - Returns: The loaded audio resource
    func loadResource(
        id: String,
        path: String,
        assetFile: String
    ) async throws -> AudioFileResource {
        // Check if resource is already cached
        if let cachedResource = resourceCache[id] {
            Logger.audio("Using cached audio resource: \(id)")
            return cachedResource
        }
        
        Logger.audio("Loading audio resource '\(id)' from \(assetFile): \(path)")
        
        do {
            // Load resource from asset file
            let resource = try await AudioFileResource(
                named: path,
                from: assetFile,
                in: contentBundle
            )
            
            // Cache the resource
            resourceCache[id] = resource
            Logger.audio("Successfully loaded and cached audio resource: \(id)")
            
            return resource
        } catch {
            Logger.audioError("Failed to load audio resource '\(id)': \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Pre-load multiple resources in a batch
    /// - Parameter resources: Array of resource specifications (id, path, assetFile)
    func preloadResources(_ resources: [(id: String, path: String, assetFile: String)]) async {
        Logger.audio("Preloading \(resources.count) audio resources")
        
        for resource in resources {
            do {
                _ = try await loadResource(id: resource.id, path: resource.path, assetFile: resource.assetFile)
            } catch {
                Logger.audioError("Failed to preload resource '\(resource.id)': \(error.localizedDescription)")
            }
        }
        
        Logger.audio("Completed preloading audio resources. Successfully loaded: \(resourceCache.count)")
    }
    
    /// Release a resource when no longer needed
    /// - Parameter id: ID of the resource to unload
    func unloadResource(id: String) {
        guard resourceCache.removeValue(forKey: id) != nil else {
            Logger.audioWarning("Attempted to unload non-existent audio resource: \(id)")
            return
        }
        
        Logger.audio("Unloaded audio resource: \(id)")
    }
    
    // MARK: - Playback Control
    
    /// Play a single sound
    /// - Parameters:
    ///   - resourceID: ID of the resource to play
    ///   - sourceID: ID of the source to play from
    ///   - loop: Whether to loop the sound
    ///   - gain: Optional gain override
    /// - Returns: The audio playback controller, or nil if playback failed
    func playSound(
        resourceID: String,
        sourceID: String,
        loop: Bool = false,
        gain: Float? = nil
    ) -> AudioPlaybackController? {
        guard var source = audioSources[sourceID] else {
            Logger.audioWarning("Attempted to play sound '\(resourceID)' from non-existent source: \(sourceID)")
            return nil
        }
        
        guard let resource = resourceCache[resourceID] else {
            Logger.audioWarning("Attempted to play non-existent audio resource: \(resourceID)")
            return nil
        }
        
        Logger.audio("Playing sound '\(resourceID)' from source '\(sourceID)' (loop: \(loop))")
        
        // Configure playback
        let configuration = AudioPlaybackConfiguration(shouldLoop: loop)
        
        // Prepare and play the audio
        let controller = source.entity.prepareAudio(resource, configuration: configuration)
        
        // Apply gain override if provided
        if let gain = gain, let spatialAudio = source.entity.spatialAudio {
            let currentGain = spatialAudio.gain
            spatialAudio.gain = gain
            
            // Reset gain when playback completes
            controller.completionHandler = { [weak self] in
                if let self = self, var updatedSource = self.audioSources[sourceID] {
                    updatedSource.entity.spatialAudio?.gain = currentGain
                    self.audioSources[sourceID] = updatedSource
                    
                    // Remove this controller from the active controllers
                    if let index = updatedSource.controllers.firstIndex(where: { $0 === controller }) {
                        updatedSource.controllers.remove(at: index)
                        self.audioSources[sourceID] = updatedSource
                    }
                }
            }
        }
        
        // Start playback
        controller.play()
        
        // Add to active controllers
        source.controllers.append(controller)
        audioSources[sourceID] = source
        
        return controller
    }
    
    /// Play a sequence of sounds with specified timing
    /// - Parameters:
    ///   - elements: Sequence elements to play
    ///   - sourceID: ID of the source to play from
    func playSequence(
        _ elements: [(sound: String, pauseAfter: TimeInterval)],
        sourceID: String
    ) async {
        let sequence = AudioSequence(elements)
        await playSequence(sequence, sourceID: sourceID)
    }
    
    /// Play a sequence of sounds with specified timing
    /// - Parameters:
    ///   - sequence: The sequence to play
    ///   - sourceID: ID of the source to play from
    func playSequence(
        _ sequence: AudioSequence,
        sourceID: String
    ) async {
        guard audioSources[sourceID] != nil else {
            Logger.audioWarning("Attempted to play sequence from non-existent source: \(sourceID)")
            return
        }
        
        Logger.audio("Starting audio sequence with \(sequence.elements.count) elements on source '\(sourceID)'")
        
        // Stop any existing playback
        stopPlayback(sourceID: sourceID)
        
        // Play each element in sequence
        for (index, element) in sequence.elements.enumerated() {
            Logger.audio("Playing sequence element \(index + 1)/\(sequence.elements.count): '\(element.resourceID)'")
            
            // Play the sound for this element
            let controller = playSound(
                resourceID: element.resourceID,
                sourceID: sourceID,
                loop: element.loop,
                gain: element.gain
            )
            
            if controller == nil {
                Logger.audioWarning("Failed to play sequence element: \(element.resourceID)")
            }
            
            // Wait for the specified duration
            if element.pauseAfterSeconds > 0 {
                Logger.audio("Pausing for \(element.pauseAfterSeconds) seconds after sound '\(element.resourceID)'")
                try? await Task.sleep(for: .seconds(element.pauseAfterSeconds))
            }
        }
        
        Logger.audio("Completed audio sequence on source '\(sourceID)'")
    }
    
    /// Stop all playback for a source
    /// - Parameter sourceID: ID of the source
    func stopPlayback(sourceID: String) {
        guard var source = audioSources[sourceID] else {
            Logger.audioWarning("Attempted to stop playback for non-existent source: \(sourceID)")
            return
        }
        
        Logger.audio("Stopping all playback for source: \(sourceID)")
        
        // Stop all active controllers
        for controller in source.controllers {
            controller.stop()
        }
        
        // Clear the controllers array
        source.controllers.removeAll()
        audioSources[sourceID] = source
    }
    
    /// Stop all audio system-wide
    func stopAllPlayback() {
        Logger.audio("Stopping all audio playback system-wide")
        
        for sourceID in audioSources.keys {
            stopPlayback(sourceID: sourceID)
        }
    }
    
    // MARK: - Audio Fading
    
    /// Fade in audio playback from silence to the specified gain level
    /// - Parameters:
    ///   - sourceID: ID of the source to fade in
    ///   - targetGain: Target gain level in decibels (defaults to current source gain)
    ///   - duration: Duration of the fade in seconds
    /// - Returns: True if fade was started, false if source not found
    @discardableResult
    func fadeIn(sourceID: String, targetGain: Float? = nil, duration: TimeInterval = 1.0) async -> Bool {
        guard let source = audioSources[sourceID], !source.controllers.isEmpty else {
            Logger.audioWarning("Attempted to fade in non-existent or silent source: \(sourceID)")
            return false
        }
        
        // Determine target gain (use existing or provided)
        let finalGain = targetGain ?? (source.entity.spatialAudio?.gain ?? 0.0)
        
        Logger.audio("Fading in source '\(sourceID)' to \(finalGain) dB over \(duration) seconds")
        
        // Start with silence
        if let spatialAudio = source.entity.spatialAudio {
            let originalGain = spatialAudio.gain
            spatialAudio.gain = -100.0 // Very quiet, but not -infinity to avoid potential issues
            
            // Apply fade to all active controllers
            for controller in source.controllers {
                // Fade in using built-in RealityKit functionality
                await controller.fade(to: finalGain, duration: duration)
            }
            
            // If no controllers (unusual case), just directly set the gain
            if source.controllers.isEmpty, let spatialAudio = source.entity.spatialAudio {
                // Simulate fade with direct gain changes
                withAnimation(.linear(duration: duration)) {
                    spatialAudio.gain = finalGain
                }
            }
        }
        
        return true
    }
    
    /// Fade out audio playback from current level to silence
    /// - Parameters:
    ///   - sourceID: ID of the source to fade out
    ///   - duration: Duration of the fade in seconds
    ///   - stopAfterFade: Whether to stop playback after fade completes
    /// - Returns: True if fade was started, false if source not found
    @discardableResult
    func fadeOut(sourceID: String, duration: TimeInterval = 1.0, stopAfterFade: Bool = true) async -> Bool {
        guard var source = audioSources[sourceID], !source.controllers.isEmpty else {
            Logger.audioWarning("Attempted to fade out non-existent or silent source: \(sourceID)")
            return false
        }
        
        Logger.audio("Fading out source '\(sourceID)' over \(duration) seconds")
        
        // Store original gain for potential restoration
        let originalGain = source.entity.spatialAudio?.gain ?? 0.0
        
        // Apply fade to all active controllers
        for controller in source.controllers {
            // Fade out using built-in RealityKit functionality
            await controller.fade(to: -100.0, duration: duration) // Very quiet, not -infinity
            
            // Stop after fade if requested
            if stopAfterFade {
                controller.stop()
            }
        }
        
        // If stopAfterFade is true, remove controllers
        if stopAfterFade {
            source.controllers.removeAll()
            audioSources[sourceID] = source
        }
        
        return true
    }
    
    /// Fade audio from current level to a target level
    /// - Parameters:
    ///   - sourceID: ID of the source to fade
    ///   - targetGain: Target gain level in decibels
    ///   - duration: Duration of the fade in seconds
    /// - Returns: True if fade was started, false if source not found
    @discardableResult
    func fade(sourceID: String, to targetGain: Float, duration: TimeInterval = 1.0) async -> Bool {
        guard let source = audioSources[sourceID], !source.controllers.isEmpty else {
            Logger.audioWarning("Attempted to fade non-existent or silent source: \(sourceID)")
            return false
        }
        
        Logger.audio("Fading source '\(sourceID)' to \(targetGain) dB over \(duration) seconds")
        
        // Apply fade to all active controllers
        for controller in source.controllers {
            // Use built-in RealityKit fade
            await controller.fade(to: targetGain, duration: duration)
        }
        
        return true
    }
    
    // MARK: - Audio Properties
    
    /// Set the gain (volume) for a source
    /// - Parameters:
    ///   - gain: New gain value in dB
    ///   - sourceID: ID of the source
    func setGain(_ gain: Float, forSource sourceID: String) {
        guard var source = audioSources[sourceID] else {
            Logger.audioWarning("Attempted to set gain for non-existent source: \(sourceID)")
            return
        }
        
        Logger.audio("Setting gain for source '\(sourceID)' to \(gain) dB")
        
        // Update spatialAudio component
        if var spatialAudio = source.entity.spatialAudio {
            spatialAudio.gain = gain
            source.entity.spatialAudio = spatialAudio
            audioSources[sourceID] = source
        } else {
            Logger.audioWarning("Source '\(sourceID)' does not have a spatialAudio component")
        }
    }
    
    /// Set the directivity pattern for a spatial source
    /// - Parameters:
    ///   - directivity: Directivity configuration
    ///   - sourceID: ID of the source
    func setDirectivity(_ directivity: SpatialAudioComponent.Directivity, forSource sourceID: String) {
        guard var source = audioSources[sourceID], source.type == .spatial else {
            Logger.audioWarning("Attempted to set directivity for non-spatial source: \(sourceID)")
            return
        }
        
        Logger.audio("Setting directivity for source '\(sourceID)'")
        
        // Update spatialAudio component
        if var spatialAudio = source.entity.spatialAudio {
            spatialAudio.directivity = directivity
            source.entity.spatialAudio = spatialAudio
            audioSources[sourceID] = source
            
            // Update debug visual to reflect new directivity
            if let debugVisual = source.debugVisual, isDebugEnabled {
                source.entity.removeChild(debugVisual)
                let newDebugVisual = createDebugVisual(for: source)
                source.entity.addChild(newDebugVisual)
                
                var updatedSource = source
                updatedSource.debugVisual = newDebugVisual
                audioSources[sourceID] = updatedSource
            }
        } else {
            Logger.audioWarning("Source '\(sourceID)' does not have a spatialAudio component")
        }
    }
    
    /// Set reverb properties for a source
    /// - Parameters:
    ///   - reverb: Reverb type
    ///   - sourceID: ID of the source
    func setReverb(_ reverb: ReverbComponent.ReverbType, forSource sourceID: String) {
        guard let source = audioSources[sourceID] else {
            Logger.audioWarning("Attempted to set reverb for non-existent source: \(sourceID)")
            return
        }
        
        Logger.audio("Setting reverb for source '\(sourceID)' to \(reverb)")
        
        // Create and set the reverb component
        let reverbComponent = ReverbComponent(reverbType: reverb)
        source.entity.components.set(reverbComponent)
    }
    
    /// Set distance attenuation properties for a source
    /// - Parameters:
    ///   - attenuation: Distance attenuation configuration
    ///   - sourceID: ID of the source
    func setDistanceAttenuation(_ attenuation: SpatialAudioComponent.DistanceAttenuation, forSource sourceID: String) {
        guard var source = audioSources[sourceID], source.type == .spatial else {
            Logger.audioWarning("Attempted to set distance attenuation for non-spatial source: \(sourceID)")
            return
        }
        
        Logger.audio("Setting distance attenuation for source '\(sourceID)'")
        
        // Update spatialAudio component
        if var spatialAudio = source.entity.spatialAudio {
            spatialAudio.distanceAttenuation = attenuation
            source.entity.spatialAudio = spatialAudio
            audioSources[sourceID] = source
        } else {
            Logger.audioWarning("Source '\(sourceID)' does not have a spatialAudio component")
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Convenience method to attach and play in one call
    /// - Parameters:
    ///   - resourceID: ID of the resource to play
    ///   - entity: Entity to attach to
    ///   - offset: Position offset from entity
    ///   - rotation: Rotation offset from entity
    ///   - loop: Whether to loop the sound
    ///   - gain: Gain for playback
    ///   - type: Type of audio source
    /// - Returns: Tuple containing sourceID and controller
    func attachAndPlay(
        resourceID: String,
        to entity: Entity,
        offset: SIMD3<Float> = .zero,
        rotation: simd_quatf = .init(),
        loop: Bool = false,
        gain: Float = 0.0,
        type: AudioType = .spatial
    ) -> (sourceID: String, controller: AudioPlaybackController?) {
        // Generate a unique ID based on entity and resource
        let sourceID = "attached_\(entity.id)_\(resourceID)_\(UUID().uuidString.prefix(8))"
        
        // Create a source attached to the entity
        _ = createSource(
            id: sourceID,
            parent: entity,
            position: offset,
            rotation: rotation,
            type: type,
            properties: SpatialAudioComponent(gain: gain)
        )
        
        // Play the sound and return the controller
        let controller = playSound(
            resourceID: resourceID,
            sourceID: sourceID,
            loop: loop
        )
        
        return (sourceID, controller)
    }
    
    /// Convenience method to attach, play with fade-in
    /// - Parameters:
    ///   - resourceID: ID of the resource to play
    ///   - entity: Entity to attach to
    ///   - offset: Position offset from entity
    ///   - rotation: Rotation offset from entity
    ///   - loop: Whether to loop the sound
    ///   - gain: Final gain after fade
    ///   - type: Type of audio source
    ///   - fadeDuration: Duration of fade-in in seconds
    /// - Returns: Tuple containing sourceID and controller
    func attachAndFadeIn(
        resourceID: String,
        to entity: Entity,
        offset: SIMD3<Float> = .zero,
        rotation: simd_quatf = .init(),
        loop: Bool = false,
        gain: Float = 0.0,
        type: AudioType = .spatial,
        fadeDuration: TimeInterval = 1.0
    ) async -> (sourceID: String, controller: AudioPlaybackController?) {
        // Generate a unique ID based on entity and resource
        let sourceID = "attached_\(entity.id)_\(resourceID)_\(UUID().uuidString.prefix(8))"
        
        // Create a source attached to the entity with initial gain set very low
        _ = createSource(
            id: sourceID,
            parent: entity,
            position: offset,
            rotation: rotation,
            type: type,
            properties: SpatialAudioComponent(gain: -100.0) // Start silent
        )
        
        // Play the sound
        let controller = playSound(
            resourceID: resourceID,
            sourceID: sourceID,
            loop: loop
        )
        
        // Fade in if controller was created
        if let controller = controller {
            await controller.fade(to: gain, duration: fadeDuration)
        }
        
        return (sourceID, controller)
    }
    
    // MARK: - Debug Visualization
    
    /// Toggle debug visualization globally
    /// - Parameter enabled: Whether to enable (nil toggles current state)
    func toggleDebugVisualization(enabled: Bool? = nil) {
        let newState = enabled ?? !isDebugEnabled
        Logger.audio("Setting debug visualization to: \(newState)")
        
        if newState != isDebugEnabled {
            isDebugEnabled = newState
            
            // Update all sources
            for (sourceID, source) in audioSources {
                if source.type == .spatial {
                    if isDebugEnabled && source.debugVisual == nil {
                        // Add debug visual
                        let debugVisual = createDebugVisual(for: source)
                        source.entity.addChild(debugVisual)
                        
                        var updatedSource = source
                        updatedSource.debugVisual = debugVisual
                        audioSources[sourceID] = updatedSource
                    } else if !isDebugEnabled && source.debugVisual != nil {
                        // Remove debug visual
                        source.debugVisual?.removeFromParent()
                        
                        var updatedSource = source
                        updatedSource.debugVisual = nil
                        audioSources[sourceID] = updatedSource
                    }
                }
            }
        }
    }
    
    /// Toggle debug visualization for a specific source
    /// - Parameters:
    ///   - id: ID of the source
    ///   - enabled: Whether to enable (nil toggles current state)
    func toggleDebugForSource(id: String, enabled: Bool? = nil) {
        guard var source = audioSources[id], source.type == .spatial else {
            Logger.audioWarning("Attempted to toggle debug for non-spatial source: \(id)")
            return
        }
        
        // Determine new state
        let currentlyEnabled = source.debugVisual != nil
        let newState = enabled ?? !currentlyEnabled
        
        Logger.audio("Setting debug visualization for source '\(id)' to: \(newState)")
        
        if newState != currentlyEnabled {
            if newState {
                // Add debug visual
                let debugVisual = createDebugVisual(for: source)
                source.entity.addChild(debugVisual)
                source.debugVisual = debugVisual
            } else {
                // Remove debug visual
                source.debugVisual?.removeFromParent()
                source.debugVisual = nil
            }
            
            // Update stored source
            audioSources[id] = source
        }
    }
    
    /// Create a debug visual for an audio source
    /// - Parameter source: The audio source
    /// - Returns: A model entity representing the directivity
    private func createDebugVisual(for source: AudioSource) -> ModelEntity {
        // Determine cone parameters based on directivity
        var height: Float = 0.2
        var radius: Float = 0.1
        var color: UIColor = .red
        
        if let spatialAudio = source.entity.spatialAudio {
            switch spatialAudio.directivity {
            case .omni:
                // Use a sphere for omnidirectional sources
                let sphere = MeshResource.generateSphere(radius: 0.05)
                
                var material = PhysicallyBasedMaterial()
                material.baseColor = .init(tint: .blue.withAlphaComponent(0.7), texture: nil)
                material.roughness = 0.8
                material.metallic = 0.0
                
                let debugSphere = ModelEntity(mesh: sphere, materials: [material])
                return debugSphere
                
            case .beam(let focus):
                // Use a cone for beam directivity
                height = 0.2 + focus * 0.3  // Longer cone for more focused beams
                radius = 0.1 - focus * 0.05  // Narrower cone for more focused beams
                color = UIColor(
                    red: CGFloat(1.0),
                    green: CGFloat(1.0 - focus),
                    blue: CGFloat(0.0),
                    alpha: 0.7
                )
            }
        }
        
        // Create the mesh (cone or sphere)
        let cone = MeshResource.generateCone(height: height, radius: radius)
        
        // Create the material
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: color, texture: nil)
        material.roughness = 0.8
        material.metallic = 0.0
        
        // Create the model entity
        let debugCone = ModelEntity(mesh: cone, materials: [material])
        
        // Set transform - point in -Z direction (default audio direction)
        debugCone.transform = Transform(
            scale: .one,
            rotation: simd_quatf(angle: .pi / 2, axis: [1, 0, 0]) * // -90 degrees around X
                     simd_quatf(angle: .pi, axis: [0, 1, 0]),      // 180 degrees around Y
            translation: [0, 0, -height / 2]  // Offset to align base with parent
        )
        
        return debugCone
    }
    
    // MARK: - Cleanup
    
    /// Clean up all audio resources
    func cleanup() {
        Logger.audio("Cleaning up all audio resources")
        
        // Stop all playback
        stopAllPlayback()
        
        // Remove all sources
        for sourceID in audioSources.keys {
            removeSource(id: sourceID)
        }
        
        // Clear resource cache
        resourceCache.removeAll()
        
        // Cancel subscriptions
        subscriptions.forEach { $0.cancel() }
        subscriptions.removeAll()
    }
} 