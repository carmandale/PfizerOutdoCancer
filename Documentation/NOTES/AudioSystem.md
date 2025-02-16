# Audio System Implementation Plan

## Overview
This document outlines the plan for implementing a unified audio system for the Pfizer Outdo Cancer VisionOS app, based on Apple's VisionOS 2 best practices and the Spaceship reference project.

## Core Design Principles

### 1. Thread Safety and Performance
- Use `@MainActor` for UI-bound operations
- Offload heavy tasks (file loading) to background threads
- Prevent main thread blocking during resource initialization

### 2. Resource Management
- Load and cache audio resources efficiently
- Proper cleanup on view dismissal
- Memory usage monitoring and optimization

### 3. Error Handling and Logging
- Comprehensive error handling strategy
- Structured logging using `os.Logger`
- User-friendly error feedback when appropriate

## Implementation Details

### 1. ADCAudioStorage Class

```swift
import RealityKit
import OSLog

private let logger = Logger(subsystem: "com.groovejones.PfizerOutdoCancer", category: "Audio")

@MainActor
final class ADCAudioStorage {
    // MARK: - Properties
    
    private var popSoundController: AudioPlaybackController?
    private var voiceOverControllers: [ADCAudioType: AudioPlaybackController] = [:]
    private var audioResources: [ADCAudioType: AudioFileResource] = [:]
    
    // Configuration
    private let fadeDuration: TimeInterval = 0.5
    private let popVolume: Float = 1.0
    private let voiceOverVolume: Float = 1.0
    
    // Task management
    private var preparationTask: Task<Void, Error>?
    
    // MARK: - Initialization
    
    func prepareAudio(for entity: Entity) async throws {
        // Cancel any existing preparation
        preparationTask?.cancel()
        
        preparationTask = Task {
            // Load resources in background
            async let popResource = AudioFileResource.loadAsync(
                named: ADCAudioType.popSound.rawValue,
                configuration: .init(
                    shouldLoop: false,
                    calibration: .absolute(dBSPL: 60)
                )
            )
            
            // Switch to MainActor for entity setup
            await MainActor.run {
                setupAudioEntities(entity)
            }
            
            // Store loaded resources
            self.audioResources[.popSound] = try await popResource
            
            // Similar pattern for voice overs...
        }
        
        try await preparationTask?.value
    }
}
```

### 2. Spatial Audio Configuration

```swift
private extension ADCAudioStorage {
    func setupAudioEntities(_ root: Entity) {
        // Pop sound setup
        let popSource = Entity()
        popSource.name = "PopSource"
        popSource.components.set(SpatialAudioComponent(
            directivity: .beam(focus: 1.0),
            attenuationParameters: .init(
                distanceAttenuationFactor: 1.0,
                maximumDistance: 10.0,
                minimumDistance: 0.1
            )
        ))
        root.addChild(popSource)
        
        // Voice over setup with different spatial characteristics
        let voSource = Entity()
        voSource.name = "VoiceOverSource"
        voSource.components.set(SpatialAudioComponent(
            directivity: .cone(angle: 60),  // Wider spread for voice
            attenuationParameters: .init(
                distanceAttenuationFactor: 0.5  // Less distance falloff
            )
        ))
        root.addChild(voSource)
    }
}
```

### 3. Playback Control

```swift
extension ADCAudioStorage {
    func playPopSound(at position: SIMD3<Float>?) {
        guard let controller = popSoundController else {
            logger.error("Pop sound controller not initialized")
            return
        }
        
        if let position = position {
            controller.entity?.position = position
        }
        
        controller.gain = popVolume
        controller.play()
    }
    
    func playVoiceOver(_ type: ADCAudioType) async {
        guard let controller = voiceOverControllers[type] else {
            logger.error("Voice over controller not found for type: \(type)")
            return
        }
        
        // Fade out current voice over
        if let current = currentVoiceOver {
            await fadeOut(current)
        }
        
        // Play new voice over
        controller.gain = 0
        controller.play()
        await fadeIn(controller)
        
        currentVoiceOver = controller
    }
    
    private func fadeOut(_ controller: AudioPlaybackController) async {
        await controller.fade(to: 0, duration: fadeDuration)
        controller.stop()
    }
    
    private func fadeIn(_ controller: AudioPlaybackController) async {
        await controller.fade(to: voiceOverVolume, duration: fadeDuration)
    }
}
```

### 4. View Integration

```swift
struct ADCOptimizedImmersive: View {
    @State private var audioStorage: ADCAudioStorage?
    @State private var preparationTask: Task<Void, Error>?
    
    var body: some View {
        RealityView { content, attachments in
            preparationTask = Task { @MainActor in
                do {
                    let storage = ADCAudioStorage()
                    try await storage.prepareAudio(for: content)
                    self.audioStorage = storage
                    
                    // Initial voice over
                    await storage.playVoiceOver(.voiceOver1)
                } catch {
                    logger.error("Failed to prepare audio: \(error.localizedDescription)")
                    // Handle error appropriately
                }
            }
        }
        .onDisappear {
            preparationTask?.cancel()
            audioStorage?.cleanup()
        }
    }
}
```

## Testing Strategy

### 1. Resource Management
- Monitor memory usage during audio loading
- Verify resource cleanup on view dismissal
- Test concurrent loading scenarios

### 2. Spatial Audio
- Verify pop sound positioning matches visual elements
- Test voice over directionality and attenuation
- Validate volume levels across different distances

### 3. Error Scenarios
- Test resource loading failures
- Verify graceful handling of missing audio files
- Monitor performance during rapid audio triggers

### 4. User Experience
- Validate fade transitions
- Test interrupt scenarios
- Verify spatial audio alignment with user movement

## Next Steps

1. Implement core `ADCAudioStorage` class
2. Add comprehensive logging
3. Setup proper error handling
4. Create test scenarios
5. Document usage patterns for team

## References

- Apple's Spaceship Game Sample Code
- VisionOS Audio Best Practices
- RealityKit Audio Documentation
