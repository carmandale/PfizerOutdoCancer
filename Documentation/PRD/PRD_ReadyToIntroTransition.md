# Ready to Intro Transition PRD

## Overview
The start button in `LoadingView` controls the transition from 2D to immersive content. When pressed, it triggers head positioning, and once positioning is complete, the loading view fades away as the immersive content becomes visible.

## Current Issues
1. Start button behavior needs to be clearly defined
2. Fade out timing needs to be coordinated with positioning
3. Transition between loading and immersive views needs to be smooth

## View Management
The app maintains consistent view presentation through phases:
```swift
// ContentView shows LoadingView for all three phases
switch appModel.currentPhase {
case .loading, .ready, .intro:
    LoadingView()
// ... other cases
}
```

## State Management
We use our existing state pattern in `IntroViewModel`:
```swift
var isRootSetupComplete: Bool = false
var isEnvironmentSetupComplete: Bool = false
var isHeadTrackingRootReady: Bool = false
var shouldUpdateHeadPosition: Bool = false
var isPositioningComplete: Bool = false

var isReadyForInteraction: Bool {
    isRootSetupComplete && 
    isEnvironmentSetupComplete && 
    isHeadTrackingRootReady
}
```

## Phase Requirements
The immersive space opening is managed through phase transitions in `PfizerOutdoCancerApp`:

```swift
// Phase change handler in PfizerOutdoCancerApp
.onChange(of: appModel.currentPhase) { oldPhase, newPhase in
    if oldPhase == newPhase { return }
    
    Task {
        // First dismiss old space if needed
        if oldPhase.needsImmersiveSpace && !newPhase.shouldKeepPreviousSpace {
            if appModel.immersiveSpaceState == .open {
                appModel.immersiveSpaceDismissReason = .manual
                await dismissImmersiveSpace()
                appModel.immersiveSpaceState = .closed
            }
        }

        // Then open new space if needed
        if newPhase.needsImmersiveSpace && !newPhase.shouldKeepPreviousSpace {
            let result = await openImmersiveSpace(id: newPhase.spaceId)
        }
    }
}

// The ImmersiveSpace definition
ImmersiveSpace(id: "IntroSpace") {
    if appModel.currentPhase == .intro {
        IntroView()
            .environment(appModel)
            .environment(adcDataModel)
    }
}
```

The sequence is:
1. `.loading` -> `.ready` transition triggers `onChange`
2. `.ready` needs immersive space, so `openImmersiveSpace(id: "IntroSpace")` is called
3. Space opens but remains empty (no `IntroView`) until `.intro` phase

## Start Button Implementation
The start button needs to trigger the head position update:

```swift
struct StartButton: View {
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        NavigationButton(
            title: "Start",
            action: {
                Task {
                    // Trigger head position update
                    appModel.introState.shouldUpdateHeadPosition = true
                }
            },
            font: .title,
            scaleEffect: AppModel.UIConstants.buttonExpandScale,
            width: 200
        )
        .fontWeight(.bold)
        .disabled(!appModel.introState.isReadyForInteraction)
    }
}
```

This triggers the sequence in `IntroView`:
```swift
.onChange(of: appModel.introState.isPositioningComplete) { _, complete in
    if complete {
        Task { @MainActor in
            if let root = appModel.introState.introRootEntity,
               let environment = appModel.introState.introEnvironment {
                // Add environment to scene
                root.addChild(environment)
                
                // Start animation sequence
                await appModel.introState.runAnimationSequence()
                appModel.introState.isSetupComplete = true
            }
        }
    }
}
```

## Implementation Flow
1. Start Button Press:
   - Sets `shouldUpdateHeadPosition = true`
   - Triggers head position update in `IntroView`

2. Head Position Update:
   - Updates position with animation
   - Sets `isPositioningComplete = true` when done

3. Position Complete:
   - Environment is added to root
   - Animation sequence starts
   - Loading view fades away

## Success Criteria
1. Start button only enabled when `isReadyForInteraction` is true
2. Head position update completes before environment appears
3. Smooth transition from loading to immersive content
4. No visible gaps during transition

## Testing Steps
1. Verify start button enables at correct time
2. Test head position update completion
3. Confirm environment appears after positioning
4. Verify smooth fade transition

By following this pattern, we ensure the immersive content appears in the correct position and with proper timing for a smooth user experience. 