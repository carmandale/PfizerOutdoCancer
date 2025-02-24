# Audio System Documentation

## Overview

The Audio System provides a comprehensive solution for managing spatial, ambient, and channel-based audio in visionOS applications. It handles audio resource loading, playback control, audio properties management, and debugging visualization while following Apple's best practices for RealityKit audio.

## Core Components

### 1. Audio Types

```swift
enum AudioType {
    case spatial   // 3D positioned audio that changes based on listener position
    case ambient   // Non-directional background audio
    case channel   // Traditional stereo/surround audio
}
```

### 2. Audio Source

Each audio source represents a point from which audio can be emitted in the scene.

```swift
struct AudioSource {
    var entity: Entity                        // The entity containing audio components
    var type: AudioType                       // Type of audio (spatial, ambient, channel)
    var parentEntity: Entity?                 // Optional parent entity
    var controllers: [AudioPlaybackController] // Active playback controllers
    var debugVisual: ModelEntity?             // Debug visualization model
    var positionOffset: SIMD3<Float>          // Position offset from parent
    var rotationOffset: simd_quatf            // Rotation offset from parent
}
```

### 3. Audio Sequence

Defines a series of audio elements to be played in sequence with specified timing.

```swift
struct AudioSequenceElement {
    let resourceID: String            // Resource ID to play
    let pauseAfterSeconds: TimeInterval // Time to pause after playback
    let gain: Float?                  // Optional gain adjustment
    let loop: Bool                    // Whether to loop the sound
}

struct AudioSequence {
    let elements: [AudioSequenceElement]  // Elements to play in sequence
    var isPlaying: Bool                   // Whether the sequence is playing
    var currentIndex: Int                 // Current position in sequence
}
```

### 4. Audio System

The main class that manages all aspects of audio:

```swift
@MainActor
class AudioSystem {
    // Core functionality areas:
    
    // 1. Source Management
    func createSource(id: String, parent: Entity?, ...) -> String
    func removeSource(id: String)
    func updateSourcePosition(id: String, position: SIMD3<Float>)
    func updateSourceRotation(id: String, rotation: simd_quatf)
    
    // 2. Resource Management
    func loadResource(id: String, path: String, assetFile: String) async throws -> AudioFileResource
    func preloadResources(_ resources: [(id: String, path: String, assetFile: String)]) async
    func unloadResource(id: String)
    
    // 3. Playback Control
    func playSound(resourceID: String, sourceID: String, loop: Bool, gain: Float?) -> AudioPlaybackController?
    func playSequence(_ elements: [(sound: String, pauseAfter: TimeInterval)], sourceID: String) async
    func stopPlayback(sourceID: String)
    func stopAllPlayback()
    
    // 4. Audio Fading
    func fadeIn(sourceID: String, targetGain: Float?, duration: TimeInterval) async -> Bool
    func fadeOut(sourceID: String, duration: TimeInterval, stopAfterFade: Bool) async -> Bool
    func fade(sourceID: String, to targetGain: Float, duration: TimeInterval) async -> Bool
    
    // 5. Audio Properties
    func setGain(_ gain: Float, forSource sourceID: String)
    func setDirectivity(_ directivity: SpatialAudioComponent.Directivity, forSource sourceID: String)
    func setReverb(_ reverb: ReverbComponent.ReverbType, forSource sourceID: String)
    func setDistanceAttenuation(_ attenuation: SpatialAudioComponent.DistanceAttenuation, forSource sourceID: String)
    
    // 6. Convenience Methods
    func attachAndPlay(resourceID: String, to entity: Entity, ...) -> (sourceID: String, controller: AudioPlaybackController?)
    func attachAndFadeIn(resourceID: String, to entity: Entity, ...) async -> (sourceID: String, controller: AudioPlaybackController?)
    
    // 7. Debug Visualization
    func toggleDebugVisualization(enabled: Bool?)
    func toggleDebugForSource(id: String, enabled: Bool?)
    
    // 8. Cleanup
    func cleanup()
}
```

## Usage Examples

### Basic Setup

```swift
// Create audio system with root entity reference
let audioSystem = AudioSystem(
    sceneContent: sceneRoot,
    bundle: Bundle.main,
    enableDebug: true
)

// Preload audio resources
await audioSystem.preloadResources([
    (id: "explosion", path: "/Root/explosion_sound", assetFile: "Assets/Game/sounds.usda"),
    (id: "background", path: "/Root/ambient_music", assetFile: "Assets/Game/music.usda")
])

// Create a spatial audio source
let sourceID = audioSystem.createSource(
    id: "playerWeapon",
    parent: playerEntity,
    position: SIMD3<Float>(0, 0.1, 0),
    type: .spatial,
    properties: SpatialAudioComponent(gain: 0.0, directivity: .beam(focus: 0.7))
)

// Play a sound
audioSystem.playSound(
    resourceID: "explosion",
    sourceID: sourceID,
    loop: false
)
```

### Fade In/Out

```swift
// Fade in background music
let musicSourceID = audioSystem.createSource(
    id: "backgroundMusic",
    parent: sceneRoot,
    type: .ambient
)

audioSystem.playSound(
    resourceID: "background",
    sourceID: musicSourceID,
    loop: true
)

await audioSystem.fadeIn(
    sourceID: musicSourceID,
    targetGain: -10.0,  // Not too loud
    duration: 3.0       // Gradually fade in over 3 seconds
)

// Later, fade out the music when scene ends
await audioSystem.fadeOut(
    sourceID: musicSourceID,
    duration: 2.0,
    stopAfterFade: true
)
```

### Audio Sequences

```swift
// Play a sequence of sounds with timing
await audioSystem.playSequence(
    [
        ("heartbeat", 2.0),   // Play heartbeat, wait 2 seconds
        ("alert", 1.0),       // Play alert, wait 1 second
        ("explosion", 0.0)    // Play explosion, no wait after
    ],
    sourceID: sourceID
)
```

### Quick Attach and Play

```swift
// Attach sound to object and play immediately
let (sourceID, controller) = audioSystem.attachAndPlay(
    resourceID: "ping",
    to: interactiveObject,
    loop: false,
    gain: 0.0
)

// Attach sound with fade-in
let (fadedSourceID, fadedController) = await audioSystem.attachAndFadeIn(
    resourceID: "ambient",
    to: roomEntity,
    loop: true,
    gain: -5.0,
    type: .ambient,
    fadeDuration: 2.0
)
```

## Best Practices

1. **Resource Management:**
   - Preload audio resources during app initialization or level loading
   - Unload resources when they are no longer needed
   - Use consistent naming conventions for resource IDs

2. **Performance:**
   - Limit the number of simultaneous audio sources (8-16 is reasonable)
   - Use ambient audio type for non-directional background sounds
   - Be mindful of audio file size and quality

3. **Spatial Audio:**
   - Position audio sources accurately in 3D space
   - Use appropriate directivity patterns (omni vs. beam)
   - Configure distance attenuation for realistic falloff

4. **User Experience:**
   - Always fade audio when starting/stopping background music
   - Keep gain levels consistent across different sound types
   - Use audio to enhance rather than dominate the experience

5. **Debugging:**
   - Use the debug visualization to see audio source positions and directivity
   - Check the logs for any audio-related warnings or errors
   - Test with different headphone types for optimal experience

## Implementation Notes

- The Audio System is designed to be used with `@MainActor` since it interacts with RealityKit entities
- All playback controllers are tracked and properly cleaned up to prevent resource leaks
- Debug visualization helps understand how audio is positioned in the 3D space
- Fade functionality uses RealityKit's built-in fade methods for smooth transitions 