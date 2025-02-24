# Audio System Quick Start Guide

This guide will help you get started with the audio system for visionOS applications. Follow these steps to quickly integrate audio features into your app.

## Installation

The audio system components are located in the `PfizerOutdoCancer/Audio` directory and include the following files:

- `AudioType.swift` - Audio source types
- `AudioSource.swift` - Audio source structure
- `AudioSequence.swift` - Audio sequence management
- `AudioSystem.swift` - Main audio system class
- `Logger+Audio.swift` - Audio logging utilities

## Step 1: Initialize the Audio System

```swift
import RealityKit
import SwiftUI

@MainActor
class MyViewModel: ObservableObject {
    private var audioSystem: AudioSystem?
    private var rootEntity: Entity?
    
    func setup(rootEntity: Entity) {
        self.rootEntity = rootEntity
        
        // Initialize audio system with root entity
        audioSystem = AudioSystem(
            sceneContent: rootEntity,
            bundle: Bundle.main,
            enableDebug: false
        )
    }
}
```

## Step 2: Load Audio Resources

```swift
func loadAudioResources() async {
    guard let audioSystem = audioSystem else { return }
    
    do {
        // Load individual resources
        _ = try await audioSystem.loadResource(
            id: "laserSound", 
            path: "/Root/laser_sound",
            assetFile: "Assets/Game/sounds.usda"
        )
        
        // Or preload multiple resources at once
        await audioSystem.preloadResources([
            (id: "explosion", path: "/Root/explosion", assetFile: "Assets/Game/sounds.usda"),
            (id: "music", path: "/Root/background_music", assetFile: "Assets/Game/music.usda")
        ])
    } catch {
        print("Failed to load audio resources: \(error)")
    }
}
```

## Step 3: Create Audio Sources

```swift
func setupAudioSources() {
    guard let audioSystem = audioSystem, let rootEntity = rootEntity else { return }
    
    // Create a spatial audio source for game effects
    audioSystem.createSource(
        id: "effectsSource",
        parent: rootEntity,
        position: SIMD3<Float>(0, 0, 0),
        type: .spatial,
        properties: SpatialAudioComponent(gain: 0.0)
    )
    
    // Create an ambient audio source for background music
    audioSystem.createSource(
        id: "musicSource",
        parent: rootEntity,
        type: .ambient,
        properties: SpatialAudioComponent(
            gain: -10.0,  // Lower volume for background
            directivity: .omni
        )
    )
}
```

## Step 4: Play Sounds

```swift
// Play a single sound
func playLaserSound() {
    audioSystem?.playSound(
        resourceID: "laserSound",
        sourceID: "effectsSource",
        loop: false
    )
}

// Play background music with fade-in
func playBackgroundMusic() async {
    guard let audioSystem = audioSystem else { return }
    
    // Play the music (looped)
    audioSystem.playSound(
        resourceID: "music",
        sourceID: "musicSource",
        loop: true
    )
    
    // Fade in over 2 seconds
    await audioSystem.fadeIn(
        sourceID: "musicSource",
        targetGain: -10.0,
        duration: 2.0
    )
}

// Play a sequence of sounds
func playAlertSequence() async {
    guard let audioSystem = audioSystem else { return }
    
    await audioSystem.playSequence(
        [
            ("alert1", 0.5),
            ("alert2", 0.5),
            ("alert3", 0.0)
        ],
        sourceID: "effectsSource"
    )
}
```

## Step 5: Attach Sounds to Entities

```swift
// Attach a sound directly to a game object
func playObjectSound(entity: Entity) {
    guard let audioSystem = audioSystem else { return }
    
    let (sourceID, _) = audioSystem.attachAndPlay(
        resourceID: "ping",
        to: entity,
        offset: SIMD3<Float>(0, 0.1, 0),
        loop: false
    )
    
    // Store the sourceID if you need to stop or fade it later
}

// Attach sound with fade-in
func playObjectAmbience(entity: Entity) async {
    guard let audioSystem = audioSystem else { return }
    
    let (sourceID, _) = await audioSystem.attachAndFadeIn(
        resourceID: "ambience",
        to: entity,
        loop: true,
        gain: -5.0,
        fadeDuration: 1.5
    )
}
```

## Step 6: Control Audio Properties

```swift
func adjustAudioProperties() {
    guard let audioSystem = audioSystem else { return }
    
    // Change volume
    audioSystem.setGain(-5.0, forSource: "effectsSource")
    
    // Set directivity for a sound (how focused it is)
    audioSystem.setDirectivity(.beam(focus: 0.7), forSource: "effectsSource")
    
    // Add reverb
    audioSystem.setReverb(.largeRoom, forSource: "effectsSource")
    
    // Configure distance attenuation
    audioSystem.setDistanceAttenuation(.rolloff(factor: 0.5), forSource: "effectsSource")
}
```

## Step 7: Stop Audio

```swift
// Stop a specific sound source
func stopEffect() {
    audioSystem?.stopPlayback(sourceID: "effectsSource")
}

// Fade out and stop background music
func fadeOutMusic() async {
    await audioSystem?.fadeOut(
        sourceID: "musicSource",
        duration: 2.0,
        stopAfterFade: true
    )
}

// Stop all audio
func stopAllAudio() {
    audioSystem?.stopAllPlayback()
}
```

## Step 8: Cleanup

```swift
func cleanup() {
    // Clean up all audio resources when no longer needed
    audioSystem?.cleanup()
    audioSystem = nil
}
```

## Step 9: Debug Visualization (Optional)

```swift
// Toggle debug visualization to see audio sources in the scene
func toggleDebugVisuals() {
    audioSystem?.toggleDebugVisualization()
}
```

## Common Patterns

### Transitioning Between Scenes

```swift
func transitionToNewScene() async {
    // Fade out current audio
    await audioSystem?.fadeOut(sourceID: "musicSource", duration: 2.0)
    
    // Scene transition logic here
    // ...
    
    // Set up new audio and fade in
    audioSystem?.createSource(id: "newSceneMusic", parent: rootEntity, type: .ambient)
    audioSystem?.playSound(resourceID: "newSceneTheme", sourceID: "newSceneMusic", loop: true)
    await audioSystem?.fadeIn(sourceID: "newSceneMusic", duration: 2.0)
}
```

### Object Interaction Sounds

```swift
func objectTapped(entity: Entity) {
    guard let audioSystem = audioSystem else { return }
    
    // Quickly attach and play a sound at the tapped object
    let (_, controller) = audioSystem.attachAndPlay(
        resourceID: "tap",
        to: entity,
        offset: .zero,
        loop: false
    )
    
    // Controller will be automatically removed when sound completes
}
```

## Tips for visionOS

- Use spatial audio for elements in the 3D environment that users can see
- Attach audio sources directly to 3D entities that emit the sound
- Use ambient audio for background music or environmental sounds
- Add debug visualization during development to verify audio source placement
- Always fade audio in/out for a smooth user experience 