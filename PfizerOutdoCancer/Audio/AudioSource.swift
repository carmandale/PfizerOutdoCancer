import RealityKit

/// Represents an audio source in the 3D scene
struct AudioSource {
    /// The entity that contains the audio component
    var entity: Entity
    
    /// The type of audio source (spatial, ambient, channel)
    var type: AudioType
    
    /// The parent entity this source is attached to, if any
    var parentEntity: Entity?
    
    /// Active audio playback controllers for this source
    var controllers: [AudioPlaybackController] = []
    
    /// Debug visualization model, if enabled
    var debugVisual: ModelEntity?
    
    /// The original position offset from parent, if attached
    var positionOffset: SIMD3<Float> = .zero
    
    /// The original rotation offset from parent, if attached
    var rotationOffset: simd_quatf = .init()
} 