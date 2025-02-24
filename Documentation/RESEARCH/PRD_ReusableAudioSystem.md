# Reusable Audio System PRD for visionOS

## Overview
This PRD outlines the design for a reusable, portable audio system for visionOS applications using RealityKit and SwiftUI. The system will support both spatial and channel-based audio playback from RealityComposer Pro packages.

## Current System Analysis
The current implementation in ADCOptimizedImmersive+Audio.swift has several limitations:
- Audio entities are tightly coupled to specific use cases
- Manual management of audio controllers and resources
- Limited reusability across different entities
- Hardcoded audio resource paths
- Complex setup process for spatial vs channel audio

## Goals
1. Create a portable, reusable audio system that can be attached to any RealityKit Entity
2. Support both spatial and channel-based audio playback
3. Simplify audio resource management from RealityComposer Pro packages
4. Provide a clean, type-safe API for audio control
5. Support proper audio positioning and spatialization
6. Enable easy audio state management using @Observable pattern

## Technical Requirements

### 1. Audio Component System
```swift
@Observable
class EntityAudioSystem {
    // Core audio properties
    var spatialAudioEnabled: Bool
    var gain: Float
    var focus: Float
    var audioResources: [String: AudioFileResource]
    
    // Audio state
    var isPlaying: Bool
    var currentAudioName: String?
    var playbackProgress: Double
}
```

### 2. Entity Extension
```swift
extension Entity {
    // Attach audio system
    func attachAudioSystem(spatial: Bool = true) -> EntityAudioSystem
    
    // Load audio from RealityComposer Pro package
    func loadAudio(named: String, from: String, in: Bundle) async throws -> AudioFileResource
}
```

### 3. Audio Configuration
- Support for different audio types:
  - Spatial Audio (3D positioned)
  - Channel Audio (Non-spatial, stereo)
- Configurable properties:
  - Gain (volume)
  - Focus (directivity for spatial audio)
  - Position relative to parent entity
  - Falloff distance
  - Reverb settings

### 4. Resource Management
- Automatic resource loading from RealityComposer Pro packages
- Resource pooling for commonly used sounds
- Proper resource cleanup
- Support for multiple audio formats (mp3, wav)

### 5. Playback Control
- Play/Stop/Pause functionality
- Loop control
- Fade in/out capabilities
- Progress tracking
- Completion handlers
- Volume control

## Implementation Guidelines

### 1. Component-Based Architecture
- Use RealityKit's ECS (Entity Component System)
- Create reusable audio components
- Support component composition

### 2. Resource Loading
```swift
// Example usage
let audioSystem = entity.attachAudioSystem()
try await audioSystem.loadResource(
    named: "sound.mp3",
    from: "AudioAssets.usda",
    type: .spatial
)
```

### 3. Playback Control
```swift
// Example usage
await audioSystem.play("sound.mp3")
await audioSystem.stop()
await audioSystem.setGain(0.5)
```

### 4. Position Management
- Automatic position updates based on entity transforms
- Support for relative positioning
- Proper handling of entity hierarchy

## Best Practices
1. Always use async/await for resource loading
2. Implement proper error handling
3. Use weak references to prevent retain cycles
4. Clean up resources when no longer needed
5. Follow visionOS audio guidelines for spatialization
6. Use appropriate audio formats and compression

## Performance Considerations
1. Resource pooling for frequently used sounds
2. Proper management of concurrent audio playback
3. Memory management for audio resources
4. CPU usage optimization
5. Battery impact considerations

## Testing Requirements
1. Unit tests for core functionality
2. Integration tests with RealityKit entities
3. Performance testing under load
4. Resource management testing
5. Spatial audio positioning accuracy tests

## Documentation Requirements
1. Detailed API documentation
2. Usage examples
3. Best practices guide
4. Performance optimization guide
5. Troubleshooting guide

## Migration Plan
1. Create new audio system implementation
2. Test with existing audio assets
3. Provide migration guide for existing code
4. Support period for both systems
5. Phase out old implementation

## Future Considerations
1. Support for advanced audio effects
2. Integration with haptics
3. Support for streaming audio
4. Advanced audio mixing capabilities
5. Audio visualization tools for debugging

## Success Metrics
1. Reduced code complexity
2. Improved performance
3. Reduced memory usage
4. Faster development time
5. Better maintainability
