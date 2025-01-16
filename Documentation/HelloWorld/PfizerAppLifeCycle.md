# Pfizer App Lifecycle Analysis

## Overview
Our app uses a centralized AppModel for state management and handles transitions through phase changes, with explicit space and window management.

## Key Components

### 1. AppModel State Management
```swift
@Observable
@MainActor
final class AppModel {
    // Phase tracking
    var currentPhase: AppPhase = .loading
    
    // Space state
    var immersiveSpaceState: ImmersiveSpaceState = .closed
    @ObservationIgnored private(set) var isTransitioning = false
    
    // Window state
    var isDebugWindowOpen = false
    var isLibraryWindowOpen = false
    var isIntroWindowOpen = false
    var isMainWindowOpen = false
    var isBuilderInstructionsOpen = false
}
```

### 2. Scene Phase Handling
```swift
@MainActor
func handleScenePhaseChange(_ newPhase: ScenePhase) async {
    switch newPhase {
    case .background, .inactive:
        isActive = false
        if immersiveSpaceState == .open {
            immersiveSpaceState = .inTransition
            currentPhase = .loading
        }
        await handTracking.stopSession()
        
    case .active:
        isActive = true
        
    @unknown default:
        break
    }
}
```

### 3. Phase-Based Transitions
```swift
@MainActor
func transitionToPhase(_ newPhase: AppPhase, adcDataModel: ADCDataModel? = nil) async {
    guard !isTransitioning else { return }
    isTransitioning = true
    
    // Handle setup if needed
    if newPhase == .playing, let adcDataModel = adcDataModel {
        if let adcEntity = await assetLoadingManager.instantiateEntity("adc") {
            gameState.setADCTemplate(adcEntity, dataModel: adcDataModel)
        }
    }
    
    currentPhase = newPhase
    isTransitioning = false
}
```

### 4. Space Management in App
```swift
// In PfizerOutdoCancerApp
.onChange(of: appModel.currentPhase) { oldPhase, newPhase in
    Task {
        if oldPhase.needsImmersiveSpace && !newPhase.shouldKeepPreviousSpace {
            await dismissImmersiveSpace()
        }
        
        await handleWindowsForPhase(newPhase)
        
        if newPhase.needsImmersiveSpace && !newPhase.shouldKeepPreviousSpace {
            await openImmersiveSpace(id: newPhase.spaceId)
        }
    }
}
```

## Key Differences from HelloWorld

1. **Phase-Based vs Navigation-Based**
   - We use explicit phases (intro, lab, building, etc.)
   - HelloWorld uses navigation path for state management

2. **State Management**
   - We track explicit transition states
   - HelloWorld uses simpler boolean flags

3. **Window Management**
   - We handle windows through phase changes
   - HelloWorld ties window state to navigation

4. **Space Transitions**
   - Our transitions are phase-driven
   - HelloWorld's transitions are navigation-driven

## Current Challenges

1. **Backgrounding Recovery**
   - Need cleaner state restoration when returning from background
   - Could benefit from navigation-style state preservation

2. **Transition Complexity**
   - Multiple state properties to track transitions
   - Could simplify using more SwiftUI-native patterns

3. **Window Management**
   - Window state spread across multiple properties
   - Could consolidate using navigation-style management

## Potential Improvements

1. Consider adopting navigation-based state preservation
2. Simplify transition state management
3. Move more logic to SwiftUI lifecycle
4. Reduce direct space/window manipulation in model
5. Implement cleaner backgrounding recovery 