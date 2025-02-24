# Migration Guide: Audio System

This guide provides instructions for migrating from the current `AttackCancerViewModel+Audio.swift` implementation to the new reusable audio system.

## Overview of Changes

The new audio system offers several improvements:

1. **Separation of Concerns**: Audio functionality is now managed by a dedicated system instead of being embedded in the view model
2. **Reusability**: The system can be used across different parts of the application
3. **Enhanced Features**: Support for audio sequences, fade in/out, debug visualization, and more
4. **Better Resource Management**: Organized approach to loading, caching, and unloading audio resources
5. **Improved Maintainability**: Clearer, more modular code structure with comprehensive logging

## Step-by-Step Migration Process

### Step 1: Initialize the Audio System

Replace audio initialization code in `AttackCancerViewModel` with the new `AudioSystem`:

**Before:**
```swift
// In AttackCancerViewModel
private func setupAudio() {
    // Audio setup code...
}
```

**After:**
```swift
// In AttackCancerViewModel
private var audioSystem: AudioSystem?

private func setupAudio() {
    // Initialize the audio system with the root entity
    audioSystem = AudioSystem(
        sceneContent: rootEntity,
        bundle: Bundle.main,
        enableDebug: false
    )
}
```

### Step 2: Replace Resource Loading

Update your audio resource loading to use the new system:

**Before:**
```swift
// Loading audio directly in the view model
private func loadAudioAssets() async {
    do {
        laserSound = try await AudioFileResource(named: "/Root/laser_sound", 
                                                from: "Assets.usda")
        // More resource loading...
    } catch {
        print("Error loading audio: \(error)")
    }
}
```

**After:**
```swift
private func loadAudioAssets() async {
    guard let audioSystem = audioSystem else { return }
    
    do {
        // Load and cache audio resources
        try await audioSystem.loadResource(
            id: "laserSound", 
            path: "/Root/laser_sound",
            assetFile: "Assets.usda"
        )
        
        // Batch load other resources
        await audioSystem.preloadResources([
            (id: "cellDestroy", path: "/Root/destroy_sound", assetFile: "Assets.usda"),
            (id: "background", path: "/Root/ambient", assetFile: "Assets.usda"),
            // Add more resources...
        ])
    } catch {
        Logger.audioError("Failed to load audio resources: \(error)")
    }
}
```

### Step 3: Set Up Audio Sources

Create audio sources for each type of sound:

```swift
private func setupAudioSources() {
    guard let audioSystem = audioSystem else { return }
    
    // Create a source for weapon sounds
    audioSystem.createSource(
        id: "weaponSource",
        parent: playerEntity,
        position: SIMD3<Float>(0, 0, 0.3), // Position relative to player
        type: .spatial,
        properties: SpatialAudioComponent(
            gain: 0.0,
            directivity: .beam(focus: 0.7)
        )
    )
    
    // Create a source for ambient background
    audioSystem.createSource(
        id: "ambientSource",
        parent: rootEntity,
        type: .ambient,
        properties: SpatialAudioComponent(
            gain: -15.0,
            directivity: .omni
        )
    )
    
    // Create other sources as needed...
}
```

### Step 4: Replace Audio Playback Functions

Update your playback functions to use the new system:

**Before:**
```swift
private func playLaserSound() {
    guard let laserSound = laserSound else { return }
    
    let audioController = weaponEntity.prepareAudio(laserSound)
    audioController.play()
}
```

**After:**
```swift
private func playLaserSound() {
    audioSystem?.playSound(
        resourceID: "laserSound",
        sourceID: "weaponSource",
        loop: false
    )
}
```

For sounds that need to be attached to specific entities:

```swift
private func playCellDestroySound(at entity: Entity) {
    guard let audioSystem = audioSystem else { return }
    
    let (sourceID, _) = audioSystem.attachAndPlay(
        resourceID: "cellDestroy",
        to: entity,
        offset: .zero,
        loop: false
    )
}
```

### Step 5: Implement Fade In/Out for Background Audio

Replace any manual volume adjustments with the new fade methods:

**Before:**
```swift
private func startBackgroundMusic() {
    // Direct playback with no fade
    backgroundEntity.playAudio(backgroundSound)
}

private func stopBackgroundMusic() {
    // Direct stop with no fade
    backgroundController?.stop()
}
```

**After:**
```swift
private func startBackgroundMusic() async {
    guard let audioSystem = audioSystem else { return }
    
    // Play the background music
    audioSystem.playSound(
        resourceID: "background",
        sourceID: "ambientSource",
        loop: true
    )
    
    // Fade in over 3 seconds
    await audioSystem.fadeIn(
        sourceID: "ambientSource", 
        duration: 3.0
    )
}

private func stopBackgroundMusic() async {
    // Fade out over 2 seconds and stop
    await audioSystem.fadeOut(
        sourceID: "ambientSource", 
        duration: 2.0
    )
}
```

### Step 6: Replace Audio Sequences

Replace any code that manually plays a sequence of sounds:

**Before:**
```swift
private func playVictorySequence() async {
    // Play first sound
    let controller1 = victoryEntity.playAudio(victorySound1)
    
    // Wait for it to complete
    await Task.sleep(for: .seconds(2))
    
    // Play second sound
    let controller2 = victoryEntity.playAudio(victorySound2)
}
```

**After:**
```swift
private func playVictorySequence() async {
    guard let audioSystem = audioSystem else { return }
    
    // Create a source if needed
    audioSystem.createSource(
        id: "victorySource",
        parent: rootEntity,
        type: .spatial
    )
    
    // Play the sequence with specified timing
    await audioSystem.playSequence(
        [
            ("victorySound1", 2.0), // Play sound1, wait 2 seconds
            ("victorySound2", 0.0)  // Play sound2, no wait after
        ],
        sourceID: "victorySource"
    )
}
```

### Step 7: Implement Cleanup

Replace any audio cleanup code with the new system's cleanup:

**Before:**
```swift
private func cleanupAudio() {
    // Manual cleanup of controllers, resources, etc.
    backgroundController?.stop()
    // More cleanup...
}
```

**After:**
```swift
private func cleanupAudio() {
    // Clean up all audio resources and controllers
    audioSystem?.cleanup()
    audioSystem = nil
}
```

### Step 8: Add Debug Visualization (Optional)

Add debug visualization for testing:

```swift
func toggleAudioDebug() {
    audioSystem?.toggleDebugVisualization()
}
```

## Example: Full Migration Pattern

Here's a template for migrating a complete audio feature:

```swift
// MARK: - Audio System

private var audioSystem: AudioSystem?

private func setupAudio() {
    // Initialize the audio system
    audioSystem = AudioSystem(
        sceneContent: rootEntity,
        bundle: Bundle.main,
        enableDebug: false
    )
    
    // Load audio resources
    Task {
        await loadAudioResources()
        await setupAudioSources()
        await startBackgroundMusic()
    }
}

private func loadAudioResources() async {
    // Implement resource loading
}

private func setupAudioSources() {
    // Set up required audio sources
}

// MARK: - Audio Playback

func playWeaponSound() {
    audioSystem?.playSound(resourceID: "weapon", sourceID: "weaponSource")
}

func playObjectInteractionSound(entity: Entity) {
    audioSystem?.attachAndPlay(resourceID: "interaction", to: entity)
}

func startBackgroundMusic() async {
    // Play and fade in background music
    audioSystem?.playSound(resourceID: "background", sourceID: "ambientSource", loop: true)
    await audioSystem?.fadeIn(sourceID: "ambientSource", duration: 2.0)
}

// MARK: - Sequences and Events

func playGameEndSequence() async {
    await audioSystem?.fadeOut(sourceID: "ambientSource", duration: 1.0)
    
    await audioSystem?.playSequence(
        [
            ("finalCountdown", 3.0),
            ("victory", 0.0)
        ],
        sourceID: "eventSource"
    )
}

// MARK: - Cleanup

func cleanupAudio() {
    audioSystem?.cleanup()
    audioSystem = nil
}
```

## Migration Checklist

Use this checklist to ensure you've covered all aspects of the migration:

- [ ] Initialize `AudioSystem` in your view model
- [ ] Migrate all audio resource loading
- [ ] Set up appropriate audio sources for all sound types
- [ ] Update all sound playback calls
- [ ] Implement fade in/out for background music and transitions
- [ ] Migrate any audio sequences
- [ ] Update audio cleanup and disposal
- [ ] Test all audio playback with debug visualization
- [ ] Verify audio properties (volume, directivity, etc.) match previous implementation
- [ ] Remove the old audio code once migration is complete

## Best Practices During Migration

1. **Migrate one feature at a time**: Start with a single sound type (e.g., background music) and gradually migrate others
2. **Test extensively**: Verify each audio feature after migration
3. **Use debug visualization**: Enable debug visuals to confirm audio source positions
4. **Keep both systems temporarily**: During migration, you can keep both systems running side by side until the transition is complete
5. **Log comparison**: Compare audio behavior between old and new systems by checking logs

## After Migration

After completing the migration:

1. Remove all code from `AttackCancerViewModel+Audio.swift`
2. Update any references to old audio methods throughout the codebase
3. Verify that audio performance is optimal
4. Consider additional audio enhancements now possible with the new system 