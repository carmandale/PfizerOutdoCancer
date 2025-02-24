# PRD: Reusable Audio System for visionOS

## Overview
This PRD outlines requirements and implementation details for a reusable audio system for visionOS applications. The goal is to create a flexible, maintainable audio management system that abstracts the complexities of RealityKit spatial audio while providing advanced features like sequencing, positional control, and visual debugging.

## Problem Statement
The current implementation in `AttackCancerViewModel+Audio.swift` tightly couples audio functionality with a specific view model, making it difficult to reuse across different views or projects. Audio setup, resource loading, and playback are intertwined with game-specific logic, resulting in code duplication when implementing similar functionality elsewhere.

Audio management in visionOS requires handling different types (spatial, ambient, channel-based), proper resource loading, entity management, and debug visualization. Without a dedicated system, these concerns get scattered across view models, reducing maintainability and consistency.

## Goals and Requirements

### Primary Goals
1. Create a reusable audio system that can be instantiated by any view model
2. Support spatial, ambient, and channel-based audio playback
3. Provide a clean API for audio attachment, positioning, and sequencing
4. Include built-in debug visualization tools for spatial audio sources
5. Improve maintainability by centralizing audio management logic

### Functional Requirements
1. **Audio Source Management**
   - Create audio sources with specific IDs
   - Attach sources to entities or position them independently
   - Configure spatial audio properties (gain, directivity, reverb)
   - Remove sources when no longer needed

2. **Resource Management**
   - Load audio resources from files asynchronously
   - Cache resources to prevent redundant loading
   - Support preloading of frequently used sounds
   - Clean up resources when no longer needed

3. **Playback Control**
   - Play individual sounds with configurable properties
   - Play sequences of sounds with timed pauses between
   - Stop, pause, and resume audio playback
   - Control gain (volume) for individual sources

4. **Spatial Positioning**
   - Attach audio to entities to inherit their position/rotation
   - Apply offsets for fine-tuned positioning
   - Update position/rotation dynamically
   - Configure distance attenuation and directivity

5. **Debug Visualization**
   - Toggle visual indicators (cones) for spatial audio sources
   - Adjust debug visual appearance based on audio properties
   - Enable/disable debug visualization globally or per-source

## Implementation Details

### Audio System Architecture

The reusable audio system will be implemented as a standalone class that can be instantiated as needed:

```swift
class AudioSystem {
    // Core references
    private var sceneContent: Entity?
    private var contentBundle: Bundle
    
    // Sources and resources tracking
    private var audioSources: [String: AudioSource] = [:]
    private var resourceCache: [String: AudioFileResource] = [:]
    
    // Debug state
    private var isDebugEnabled: Bool = false
    
    // Methods for audio management...
}
```

### Key Components

#### AudioType Enum
Defines the spatial behavior of audio sources:

```swift
enum AudioType {
    case spatial  // 3D positioned, directional audio (default)
    case ambient  // Non-directional background audio
    case channel  // Stereo/surround channel-based audio
}
```

#### AudioSource Structure
Tracks an audio source and its associated entities and controllers:

```swift
struct AudioSource {
    var entity: Entity
    var type: AudioType
    var controllers: [AudioPlaybackController] = []
    var debugVisual: ModelEntity?
    var parentEntity: Entity?  // The entity this source is attached to, if any
}
```

#### AudioSequenceElement
Defines an element in an audio sequence with timing information:

```swift
struct AudioSequenceElement {
    let resourceID: String
    let pauseAfterSeconds: TimeInterval
}
```

### Core API Methods

#### Source Creation and Management

```swift
// Create a new audio source with the specified properties
func createSource(
    id: String,
    parent: Entity? = nil,
    position: SIMD3<Float> = .zero,
    rotation: simd_quatf = .init(),
    type: AudioType = .spatial,
    properties: SpatialAudioComponent? = nil
) -> String

// Remove an audio source and its resources
func removeSource(id: String)

// Update the position of an existing source
func updateSourcePosition(id: String, position: SIMD3<Float>)

// Update the rotation of an existing source
func updateSourceRotation(id: String, rotation: simd_quatf)
```

#### Resource Management

```swift
// Load an audio resource from a file
func loadResource(
    id: String,
    path: String,
    assetFile: String
) async throws -> AudioFileResource

// Pre-load multiple resources in a batch
func preloadResources(_ resources: [(id: String, path: String, assetFile: String)]) async

// Release resources no longer needed
func unloadResource(id: String)
```

#### Playback Control

```swift
// Play a single sound
func playSound(
    resourceID: String,
    sourceID: String,
    loop: Bool = false,
    gain: Float? = nil
) -> AudioPlaybackController?

// Play a sequence of sounds with specified timing
func playSequence(
    _ elements: [(sound: String, pauseAfter: TimeInterval)],
    sourceID: String
) async

// Stop all playback for a source
func stopPlayback(sourceID: String)

// Stop all audio system-wide
func stopAllPlayback()
```

#### Audio Properties

```swift
// Set the gain (volume) for a source
func setGain(_ gain: Float, forSource sourceID: String)

// Set the directivity pattern for a spatial source
func setDirectivity(_ directivity: SpatialAudioComponent.Directivity, forSource sourceID: String)

// Set reverb properties for a source
func setReverb(_ reverb: ReverbComponent.ReverbType, forSource sourceID: String)

// Set distance attenuation properties
func setDistanceAttenuation(_ attenuation: SpatialAudioComponent.DistanceAttenuation, forSource sourceID: String)
```

#### Convenience Methods

```swift
// Convenience method to attach and play in one call
func attachAndPlay(
    resourceID: String,
    to entity: Entity,
    offset: SIMD3<Float> = .zero,
    rotation: simd_quatf = .init(),
    loop: Bool = false,
    gain: Float = 0.0,
    type: AudioType = .spatial
) -> (sourceID: String, controller: AudioPlaybackController?)
```

#### Debug Visualization

```swift
// Toggle debug visualization globally
func toggleDebugVisualization(enabled: Bool? = nil)

// Toggle debug for a specific source
func toggleDebugForSource(id: String, enabled: Bool? = nil)

// Create a debug visual for an audio source
private func createDebugVisual(
    for source: AudioSource,
    directivity: SpatialAudioComponent.Directivity
) -> ModelEntity
```

## Usage Examples

### Basic Setup and Playback

```swift
// In a ViewModel
private var audioSystem: AudioSystem?

func setupAudio() {
    // Create audio system
    audioSystem = AudioSystem(
        sceneContent: rootEntity,
        bundle: realityKitContentBundle,
        enableDebug: true
    )
}

func loadAudioResources() async {
    // Load resources
    try? await audioSystem?.loadResource(
        id: "explosion",
        path: "/Root/explosion_wav",
        assetFile: "Assets/Game/sounds.usda"
    )
}

func playSound() {
    // Play a sound
    audioSystem?.playSound(
        resourceID: "explosion",
        sourceID: "effectsSource",
        loop: false,
        gain: -5.0
    )
}
```

### Creating and Using a Spatial Audio Source

```swift
// Create a source attached to an entity
let sourceID = audioSystem?.createSource(
    id: "characterVoice",
    parent: characterEntity,
    position: SIMD3<Float>(0, 0.2, 0),  // Offset from entity position
    type: .spatial,
    properties: SpatialAudioComponent(
        gain: 0.0,
        directivity: .beam(focus: 0.8)
    )
)

// Play a sound from this source
audioSystem?.playSound(
    resourceID: "voiceLine1",
    sourceID: "characterVoice"
)
```

### Playing a Sequence of Sounds

```swift
// Define and play a sequence
Task {
    await audioSystem?.playSequence(
        [
            ("intro", 1.5),     // Play intro, wait 1.5 seconds
            ("middle", 0.8),    // Play middle, wait 0.8 seconds
            ("ending", 0.0)     // Play ending, no wait after
        ],
        sourceID: "narratorVoice"
    )
}
```

## Benefits

### Improved Organization
Centralizing audio logic in a dedicated system improves code organization and reduces duplication.

### Reusability
The system can be used across different views and projects, ensuring consistent audio behavior.

### Maintainability
Changes to audio implementation only need to happen in one place, making maintenance easier.

### Debugging
Built-in visualization tools make spatial audio positioning more intuitive and easier to debug.

### Performance
Resource caching and proper cleanup improve performance by reducing redundant loading.

## Additional Considerations

### Threading
Audio operations, especially resource loading, should be handled asynchronously to avoid blocking the main thread.

### Memory Management
The system should provide proper cleanup methods to release audio resources when no longer needed.

### Error Handling
Robust error handling for resource loading failures with clear logging will improve debugging.

### Versioning
The system should be designed to accommodate future updates to RealityKit's audio capabilities.

## Implementation Plan

1. **Phase 1: Core System Implementation**
   - Implement basic `AudioSystem` class
   - Create source management functionality
   - Implement resource loading and caching

2. **Phase 2: Playback and Control**
   - Implement single sound playback
   - Add sequence playback functionality
   - Implement audio property controls

3. **Phase 3: Debug Visualization**
   - Implement debug visuals for spatial sources
   - Add toggle controls for debug visualization

4. **Phase 4: Migration and Testing**
   - Migrate existing audio from `AttackCancerViewModel`
   - Test with various audio types and scenarios
   - Document the API for team reference 