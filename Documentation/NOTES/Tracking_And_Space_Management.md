# Tracking and Space Management in visionOS 2
> A guide for improving our existing tracking and space management implementation following Apple's best practices

## Current Problems and Concerns

### Tracking State Management Issues
1. **Inconsistent State Transitions**
   - Lab environment positioning varies between first and second attempts
   - Head position tracking doesn't reliably reset between transitions
   - Arbitrary delays used instead of proper state observation

2. **Space Management Challenges**
   - Scene positioning can be unpredictable during phase transitions
   - Lab environment sometimes positions too low on re-entry
   - Lack of proper cleanup between space transitions

3. **Tracking Session Lifecycle**
   - Multiple tracking tasks running independently
   - No centralized tracking state management
   - Potential memory leaks from undisposed tracking sessions

4. **Performance Impact**
   - Polling loops creating unnecessary CPU load
   - ClosureComponent updates potentially affecting frame rate
   - Redundant tracking checks across different views

### Critical Areas for Improvement
1. **State Synchronization**
   - Need proper state observation for tracking providers
   - Better coordination between tracking and space states
   - Reliable head position tracking across transitions

2. **Resource Management**
   - Proper cleanup of tracking resources
   - Better memory management for long-running sessions
   - Efficient hand tracking updates

3. **Error Recovery**
   - Graceful handling of tracking interruptions
   - Better user feedback for tracking issues
   - Automatic recovery strategies

## Pragmatic Priority List

### Critical Issues (Must Fix)
1. **Lab Positioning Inconsistency**
   - Problem: Lab environment positions too low on second entry
   - Impact: Direct user experience issue
   - Risk Level: Low (focused fix)
   - Approach: 
     * Log and analyze head position values during transitions
     * Compare successful vs problematic transitions
     * Focus on the specific transition code path

2. **Tracking Reset Between Transitions**
   - Problem: Head position tracking doesn't reliably reset
   - Impact: Affects scene positioning
   - Risk Level: Medium
   - Approach:
     * Document successful transition patterns
     * Add logging around tracking state changes
     * Verify cleanup sequence

### Important (Should Fix)
1. **Resource Management**
   - Problem: Potential memory leaks from tracking sessions
   - Impact: Long-term stability
   - Risk Level: Medium
   - Approach:
     * Add diagnostics to verify leak existence
     * Document current session lifecycle
     * Plan careful cleanup improvements

2. **Performance Optimization**
   - Problem: Polling and redundant checks
   - Impact: CPU usage
   - Risk Level: Low-Medium
   - Approach:
     * Measure actual performance impact
     * Identify worst offenders
     * Plan targeted optimizations

### Nice to Have (Consider Later)
1. **Modern API Usage**
   - Current: Using ClosureComponent for updates (working well, no need to change)
   - Note: While Systems are an alternative pattern, our ClosureComponent implementation is proven and reliable
   - Risk Level: High
   - Decision: Keep current implementation

2. **Predicted Tracking Mode**
   - Current: Standard tracking mode
   - Proposed: New visionOS 2 predicted mode
   - Risk Level: High
   - Decision: Wait for more community feedback

### Implementation Guidelines
1. **Before Any Change**
   - Document current working behavior
   - Add logging to understand the flow
   - Create test cases for verification

2. **During Implementation**
   - Make minimal, focused changes
   - Test extensively on device
   - Keep original code paths available for rollback

3. **After Changes**
   - Verify all transitions still work
   - Check performance metrics
   - Document what was learned

### Risk Mitigation
1. **Keep What Works**
   - Our current implementation is functional
   - Many issues are optimization opportunities, not blockers
   - Preserve working code paths when making changes

2. **Careful Testing**
   - Test each change in isolation
   - Verify on multiple devices if possible
   - Test edge cases (low battery, background transitions)

3. **Rollback Plan**
   - Maintain current implementation
   - Use feature flags for new code paths
   - Document exact changes and their effects

## Apple's Best Practices Analysis

### Current Implementation vs Apple Guidelines

1. **World Tracking (✅ Good / ⚠️ Needs Improvement)**
   - ✅ Using RealityKit's SpatialTrackingSession
   - ✅ Proper Full Space and permissions setup
   - ⚠️ Not properly waiting for tracking initialization
   - ⚠️ Using polling instead of state observation
   - ⚠️ Inconsistent session lifecycle management

2. **Hand Tracking (✅ Good / ⚠️ Needs Improvement)**
   - ✅ Proper use of HandTrackingProvider
   - ✅ Correct permissions implementation
   - ⚠️ Not using the new visionOS 2 predicted mode
   - ⚠️ Performance impact from ClosureComponent
   - ⚠️ Lack of proper concurrency in updates

3. **State Management (✅ Good / ⚠️ Needs Improvement)**
   - ✅ Basic error handling structure
   - ✅ Good authorization handling
   - ⚠️ Not using proper state observation
   - ⚠️ Manual polling for state changes
   - ⚠️ Arbitrary delays in tracking restarts

### Key visionOS 2 Improvements to Implement

1. **Use New APIs**
   ```swift
   // Replace current polling with proper state observation
   for await event in arkitSession.events {
       if case .dataProviderStateChanged(_, let newState, _) = event {
           // Handle state change properly
       }
   }
   ```

2. **Leverage Predicted Tracking**
   ```swift
   // Enable predicted mode for reduced latency
   let config = HandTrackingProvider.Configuration()
   config.trackingMode = .predicted  // New in visionOS 2
   ```

3. **Proper State Management**
   ```swift
   // Wait for proper initialization
   func waitForTrackingState(_ desiredState: TrackingState) async throws {
       for await state in trackingStateUpdates {
           if state == desiredState {
               return
           }
       }
   }
   ```

### Implementation Priorities Based on Apple Guidelines

1. **Immediate Fixes**
   - Replace polling with proper state observation
   - Implement proper session lifecycle management
   - Add tracking state initialization waiting

2. **Performance Improvements**
   - Move to predicted tracking mode
   - Replace ClosureComponent with System
   - Implement proper concurrency

3. **Stability Enhancements**
   - Add proper error recovery
   - Improve state synchronization
   - Enhance cleanup procedures

## Overview
This document outlines improvements to our current tracking and space management implementation in our visionOS 2 app, ensuring we follow Apple's recommended patterns while building on our existing architecture.

## Current Implementation Analysis

### TrackingSessionManager Strengths
- Proper use of ARKitSession and providers
- Good authorization handling
- Async/await usage
- Error handling structure
- State monitoring

### HandTrackingManager Strengths
- Clean separation of concerns
- Efficient entity management
- Proper use of RealityKit components
- Good hand position tracking
- Memory management (weak references)

## Proposed Improvements

### 1. Enhanced State Management
Replace polling with proper state observation in TrackingSessionManager:

```swift
extension TrackingSessionManager {
    func waitForProviderState(_ desiredState: DataProviderState) async throws {
        for await event in arkitSession.events {
            if case .dataProviderStateChanged(_, let newState, _) = event {
                if newState == desiredState {
                    return
                }
            }
        }
    }
    
    func ensureTrackingState(_ state: DataProviderState) async throws {
        switch state {
        case .running:
            if !isTracking {
                try await startTracking()
                try await waitForProviderState(.running)
            }
        case .stopped:
            if isTracking {
                stopTracking()
                try await waitForProviderState(.stopped)
            }
        default:
            break
        }
    }
}
```

### 2. Dedicated Hand Tracking System
Replace ClosureComponent with a proper System:

```swift
class HandTrackingSystem: System {
    static let query = EntityQuery(where: .has(HandTrackingComponent.self))
    
    private let handTrackingManager: HandTrackingManager
    
    init(scene: Scene, handTrackingManager: HandTrackingManager) {
        self.handTrackingManager = handTrackingManager
    }
    
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            updateHandPositions(for: entity)
        }
    }
}

struct HandTrackingComponent: Component {
    var leftHandEnabled: Bool = true
    var rightHandEnabled: Bool = true
}
```

### 3. Improved Error Handling
Enhance our existing error handling:

```swift
extension TrackingSessionManager {
    enum TrackingError: Error {
        case stateTransitionTimeout
        case providerError(Error)
        case invalidState(DataProviderState)
        case authorizationDenied
    }
    
    func handleTrackingError(_ error: Error) async throws {
        print("❌ Tracking error encountered: \(error)")
        
        switch error {
        case TrackingError.stateTransitionTimeout:
            // Attempt recovery
            try await restartTracking()
        case TrackingError.providerError(let underlyingError):
            // Handle provider-specific errors
            try await handleProviderError(underlyingError)
        default:
            throw error
        }
    }
}
```

## Implementation Strategy

### Phase 1: State Management
1. Add waitForProviderState to TrackingSessionManager
2. Implement ensureTrackingState
3. Remove polling loops
4. Add comprehensive state logging

### Phase 2: Hand Tracking
1. Create HandTrackingSystem
2. Add HandTrackingComponent
3. Migrate from ClosureComponent
4. Update HandTrackingManager integration

### Phase 3: Error Handling
1. Enhance error types
2. Implement recovery strategies
3. Add error logging
4. Improve user feedback

## Best Practices Alignment

### ✅ Current Good Practices to Keep
- ARKitSession usage
- Authorization handling
- Async/await patterns
- Basic error handling
- Entity management

### ✅ Improvements to Add
- State-based tracking management
- System-based hand tracking
- Enhanced error recovery
- Better state synchronization
- Improved logging

### ❌ Patterns to Remove
- Polling loops
- Arbitrary delays
- Manual state management

## Next Steps
1. Implement state management improvements
2. Create and test HandTrackingSystem
3. Enhance error handling
4. Add comprehensive logging
5. Test state transitions
6. Validate performance

## References
- [Apple's visionOS Documentation](https://developer.apple.com/documentation/visionos)
- [RealityKit Documentation](https://developer.apple.com/documentation/realitykit)
- [Spatial Computing Guidelines](https://developer.apple.com/design/human-interface-guidelines/spatial-computing) 