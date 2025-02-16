# Asset Loading and Phase Transition Strategy

## Overview
This document outlines the strategy for managing asset loading and phase transitions in the Pfizer Outdo Cancer visionOS app. The goal is to ensure smooth transitions between phases while maintaining optimal memory usage through strategic asset loading and unloading.

## Current Working System Analysis

### Asset Loading Pattern
- On-demand loading through `AssetLoadingManager`
- Asset name mappings for consistent naming
- Successful memory management through selective loading/unloading

### Lab Environment Specifics
1. **Assembled Lab**
   - Core lab environment loaded as single asset
   - Includes all interactive devices (laptops, monitors)
   - Currently working well with memory management

2. **Interactive Devices**
   - Part of assembled lab asset
   - Configuration happens in `configureInteractiveDevices`
   - Uses existing shader system for hover effects
   - Working pattern we should preserve

3. **Audio and VO**
   - Loaded separately from assembled lab
   - Can be loaded/unloaded without affecting core environment

## Enhanced Loading Strategy

### 1. Loading States and Configuration
```swift
enum SceneLoadingState {
    case notLoaded
    case loading(progress: Float)
    case ready
    case error(Error)
}

// Track loading state for each major scene
private var introLoadingState: SceneLoadingState
private var labLoadingState: SceneLoadingState
private var playingLoadingState: SceneLoadingState

// Loading configuration
private let loadingTimeout: TimeInterval = 30  // Maximum wait time
private let retryAttempts = 3  // Number of retry attempts
private let retryDelay: TimeInterval = 1.0  // Delay between retries
```

### 2. Initial Loading (App Start)
- Triggered by `LoadingView`
- Uses `AppModel.startLoading()`
- Leverages existing LoadingView progress bar
- Preloads:
  1. Intro environment and assets
  2. Assembled lab (used in both intro portal and lab)

### 3. Phase-Specific Asset Management

#### Asset Phase Mapping
```swift
struct PhaseAssets {
    let requiredAssets: [String]
    let optionalAssets: [String]
    let retainedAssets: [String]
}

private let phaseAssetMapping: [AppPhase: PhaseAssets] = [
    .intro: PhaseAssets(
        requiredAssets: [
            "intro_environment",
            "intro_warp",
            "pfizer_logo",
            "title_card"
        ],
        optionalAssets: [],
        retainedAssets: ["assembled_lab"]  // For portal
    ),
    .lab: PhaseAssets(
        requiredAssets: [
            "lab_vo",
            "lab_audio"
        ],
        optionalAssets: [],
        retainedAssets: ["assembled_lab"]  // Keep from intro
    ),
    .playing: PhaseAssets(
        requiredAssets: [
            "attack_cancer_environment",
            "adc",
            "cancer_cell",
            "game_start_vo"
        ],
        optionalAssets: [],
        retainedAssets: []  // Consider if we need assembled_lab
    ),
    .outro: PhaseAssets(
        requiredAssets: ["outro_environment"],
        optionalAssets: [],
        retainedAssets: []
    )
]
```

### 4. Error Recovery Strategy
- Implement retry logic for failed asset loads
- Use placeholder assets where possible
- Graceful degradation for non-critical assets
- Clear user feedback through LoadingView
- Timeout handling with appropriate user messaging

## Implementation Strategy

### 1. Asset Preparation
- Preserve current working asset loading system
- Add state tracking and progress monitoring
- Keep existing shader and interactive device configuration
- Add retry logic with configurable attempts

```swift
private func loadAssetWithRetry(_ asset: String, phase: AppPhase) async throws {
    var attempts = 0
    while attempts < retryAttempts {
        do {
            try await assetLoadingManager.loadAsset(withName: asset, category: categoryFor(phase))
            return
        } catch {
            attempts += 1
            if attempts == retryAttempts { throw error }
            try await Task.sleep(for: .seconds(retryDelay))
        }
    }
}
```

### 2. Phase Transitions
```swift
func prepareForPhase(_ phase: AppPhase) async throws {
    // Load assets before transition with progress tracking
    updateLoadingState(for: phase, to: .loading(progress: 0))
    
    do {
        try await withTimeout(seconds: loadingTimeout) {
            try await loadPhaseAssets(for: phase)
        }
        updateLoadingState(for: phase, to: .ready)
    } catch {
        updateLoadingState(for: phase, to: .error(error))
        throw error
    }
}

func transitionToPhase(_ newPhase: AppPhase) async {
    // Ensure assets are ready
    // Use existing release patterns
    // Maintain working configuration flows
    // Handle transition UI/UX
}
```

### 3. User Experience Enhancements
- Leverage LoadingView for all asset loading feedback
- Smooth transitions with fade animations
- Progress indicators for background loading
- Clear error messaging
- Graceful fallbacks for failed loads

### 4. Memory Management

#### Monitoring Strategy
- Track memory usage during phase transitions
- Monitor asset cache size
- Implement memory pressure handling
- Automatic cleanup of unused assets

#### Release Priorities
1. Audio assets (can be reloaded)
2. Optional visual assets
3. Phase-specific required assets
4. Shared assets (like assembled_lab)

### 5. Key Points to Preserve
1. Keep assembled lab as single asset
2. Maintain current interactive device configuration
3. Preserve working shader system
4. Keep separate audio/VO loading

## Additional Implementation Considerations

### 1. Concurrency and Race Conditions
```swift
final class AssetLoadingManager {
    // Task cancellation support
    private var currentLoadingTask: Task<Void, Error>?
    
    func cancelCurrentLoading() {
        currentLoadingTask?.cancel()
        currentLoadingTask = nil
    }
    
    func prepareForPhase(_ phase: AppPhase) async throws {
        // Cancel any existing loading
        cancelCurrentLoading()
        
        // Create new loading task
        currentLoadingTask = Task {
            try await loadPhaseAssets(for: phase)
        }
        
        // Wait for completion or cancellation
        try await currentLoadingTask?.value
    }
}
```

#### Key Points:
- Track and manage loading tasks
- Support clean cancellation
- Handle task replacement for quick transitions
- Synchronize state updates

### 2. Enhanced Error Handling

#### Error Classification
```swift
enum AssetLoadingError: Error {
    case timeout(asset: String)
    case networkError(asset: String, underlying: Error)
    case resourceMissing(asset: String)
    case memoryPressure
    case cancelled
    
    var isRecoverable: Bool {
        switch self {
        case .networkError, .timeout:
            return true
        case .resourceMissing, .memoryPressure:
            return false
        case .cancelled:
            return true
        }
    }
}
```

#### Error Recovery Strategy
```swift
func handleAssetLoadingError(_ error: AssetLoadingError, phase: AppPhase) async {
    switch error {
    case .networkError, .timeout:
        // Show retry prompt
        if await shouldRetryLoading() {
            try? await prepareForPhase(phase)
        } else {
            await fallbackToPlaceholder(for: phase)
        }
    case .resourceMissing:
        // Log critical error
        await showCriticalErrorMessage()
    case .memoryPressure:
        // Attempt cleanup and retry
        await handleMemoryPressure()
        try? await prepareForPhase(phase)
    case .cancelled:
        // Clean up and proceed with new task
        break
    }
}
```

### 3. Performance Monitoring

#### Memory Tracking
```swift
struct MemoryMetrics {
    let totalAssets: Int
    let cachedAssetSize: Int
    let availableMemory: Int
    
    var shouldTriggerCleanup: Bool {
        // Implementation based on metrics
    }
}

func trackMemoryUsage() async {
    for await metrics in memoryMetricsStream {
        if metrics.shouldTriggerCleanup {
            await performMemoryCleanup()
        }
    }
}
```

#### Loading Performance
```swift
struct LoadingMetrics {
    let assetName: String
    let loadDuration: TimeInterval
    let retryCount: Int
    let success: Bool
}

func logLoadingMetrics(_ metrics: LoadingMetrics) {
    // Log metrics for analysis
}
```

### 4. Transition Synchronization

#### UI State Management
```swift
struct TransitionState {
    let sourcePhase: AppPhase
    let targetPhase: AppPhase
    let progress: Float
    let loadingStatus: LoadingStatus
    
    enum LoadingStatus {
        case preparing
        case loadingAssets(progress: Float)
        case configuringScene
        case complete
        case error(AssetLoadingError)
    }
}

func updateTransitionUI(for state: TransitionState) {
    // Update loading indicators
    // Manage fade animations
    // Show appropriate messages
}
```

## Testing Strategy

### 1. Unit Tests
- Loading state transitions
- Error handling paths
- Memory management triggers
- Task cancellation

### 2. Integration Tests
- Phase transitions
- Asset loading sequences
- Memory pressure handling
- UI feedback accuracy

### 3. Performance Tests
- Loading times under various conditions
- Memory usage patterns
- Transition smoothness
- Error recovery times

### 4. User Experience Tests
- Loading indicator accuracy
- Animation smoothness
- Error message clarity
- Transition feel

## Monitoring and Maintenance

### 1. Runtime Metrics
- Asset loading times
- Memory usage patterns
- Error frequencies
- User interaction patterns

### 2. Error Tracking
- Categorize errors by type
- Track retry patterns
- Monitor recovery success rates
- Log user impact

### 3. Performance Optimization
- Regular memory usage review
- Loading time optimization
- Cache effectiveness analysis
- Transition smoothness monitoring

## Notes
- Preserve working patterns for interactive devices
- Keep shader system as is
- Maintain current asset organization
- Focus on enhancing transitions while keeping working systems intact
- Implement robust error handling
- Monitor memory usage and adjust retention strategy
- Use background loading during idle periods
- Maintain main thread responsiveness
- Log all operations for debugging
- Implement comprehensive logging for debugging and metrics
- Monitor real-world performance and adjust timeouts/retries
- Regular review of retained assets and memory patterns
- Maintain clear error messages for all failure modes

# Asset Loading and Phase Transitions Implementation Plan

## 1. Entity Release Implementation

First, we'll update our entity release mechanism in `AssetLoadingManager`:

```swift
/// Releases an entity and all its resources
func releaseEntity(_ entity: Entity) {
    // 1. Log the hierarchy before removal for debugging
    print("\n📝 Releasing entity: \(entity.name)")
    print("  - Child count: \(entity.children.count)")
    print("  - Has components: \(entity.components.isEmpty ? "no" : "yes")")
    
    // 2. Recursively release all children first
    for child in entity.children {
        releaseEntity(child)
    }
    
    // 3. Stop any active audio components
    if var audioComponent = entity.components[AudioComponent.self] as? AudioComponent {
        print("  - Stopping audio component")
        audioComponent.stop()
    }
    
    // 4. Remove all components
    entity.components.removeAll()
    
    // 5. Remove from parent
    if let parent = entity.parent {
        print("  - Detaching from parent: \(parent.name)")
        entity.removeFromParent()
    }
    
    print("✅ Released entity: \(entity.name)\n")
}
```

## 2. Template Management Updates

Update the template management system to handle shared assets better:

```swift
final class AssetLoadingManager {
    /// Tracks reference counts for shared assets
    private var sharedAssetReferences: [String: Int] = [:]
    
    /// Retains a shared asset
    func retainSharedAsset(_ key: String) {
        sharedAssetReferences[key, default: 0] += 1
        print("📈 Retained shared asset '\(key)' - Current references: \(sharedAssetReferences[key] ?? 0)")
    }
    
    /// Releases a shared asset
    func releaseSharedAsset(_ key: String) {
        guard let count = sharedAssetReferences[key], count > 0 else { return }
        sharedAssetReferences[key] = count - 1
        print("📉 Released shared asset '\(key)' - Current references: \(sharedAssetReferences[key] ?? 0)")
        
        // If no more references, consider removing from templates
        if sharedAssetReferences[key] == 0 {
            print("🗑️ No more references to '\(key)' - Removing from templates")
            entityTemplates.removeValue(forKey: key)
        }
    }
}
```

## 3. Phase-Specific Asset Management

Update phase transitions to handle assets more carefully:

```swift
extension AppModel {
    func transitionToPhase(_ newPhase: AppPhase) async {
        print("🔄 Phase transition: \(currentPhase) -> \(newPhase)")
        
        // 1. Preload assets for new phase
        do {
            switch newPhase {
            case .intro:
                try await preloadIntroAssets()
            case .lab:
                try await preloadLabAssets()
            case .building:
                try await preloadBuildingAssets()
            case .playing:
                try await preloadPlayingAssets()
            default:
                break
            }
        } catch {
            print("❌ Failed to preload assets for \(newPhase): \(error)")
            return
        }
        
        // 2. Clean up current phase
        await cleanupPhase(currentPhase)
        
        // 3. Complete transition
        currentPhase = newPhase
    }
    
    private func cleanupPhase(_ phase: AppPhase) async {
        print("\n=== Cleaning up phase: \(phase) ===")
        
        switch phase {
        case .intro:
            await assetLoadingManager.releaseIntroEnvironment()
        case .lab:
            await assetLoadingManager.releaseLabEnvironment()
            // Release shared assets if no longer needed
            if currentPhase != .building && currentPhase != .playing {
                assetLoadingManager.releaseSharedAsset("assembled_lab")
            }
        default:
            break
        }
    }
}
```

## 4. Memory Pressure Handler Updates

Make the memory pressure handler phase-aware:

```swift
func handleMemoryWarning() {
    print("\n⚠️ === Handling Memory Pressure ===")
    print("📊 Before cleanup - Template cache size: \(entityTemplates.count) entities")
    
    // Define essential assets based on current phase
    let essentialKeys: [String]
    switch AppModel.shared.currentPhase {
    case .intro:
        essentialKeys = ["intro_environment"]
    case .lab, .building:
        essentialKeys = ["assembled_lab"]
    case .playing:
        essentialKeys = ["assembled_lab", "cancer_cell"]
    default:
        essentialKeys = []
    }
    
    let nonEssentialKeys = entityTemplates.keys.filter { !essentialKeys.contains($0) }
    
    print("\n🔒 Essential assets to retain: \(essentialKeys)")
    print("🗑️ Non-essential assets to release: \(nonEssentialKeys)")
    
    // Release non-essential assets
    for key in nonEssentialKeys {
        if let entity = entityTemplates[key] {
            releaseEntity(entity)
            entityTemplates.removeValue(forKey: key)
            print("  - Released: \(key)")
        }
    }
    
    print("\n📊 After cleanup - Template cache size: \(entityTemplates.count) entities")
    print("✅ Memory pressure handling complete\n")
}
```

## Implementation Steps

1. **Update AssetLoadingManager**
   - Implement the new `releaseEntity` function
   - Add shared asset reference counting
   - Update the memory pressure handler

2. **Update Phase Transitions**
   - Implement preloading for each phase
   - Update cleanup logic
   - Add proper logging

3. **Audio Handling**
   - Ensure audio components are properly stopped
   - Add explicit cleanup for audio resources

4. **Testing**
   - Test each phase transition
   - Monitor memory usage
   - Use Memory Graph Debugger to check for retain cycles

## Verification Steps

After implementation:

1. Check memory usage during phase transitions
2. Verify audio resources are properly released
3. Monitor template cache size
4. Use Memory Graph Debugger to verify no retain cycles
5. Test under memory pressure conditions

## Notes

- Keep `assembled_lab` cached until explicitly not needed
- Always stop audio before removing components
- Log all entity releases for debugging
- Use Memory Graph Debugger frequently during testing 