# Tracking Session Management Implementation Guide

## Overview

This document defines the implementation requirements for handling ARKit tracking sessions in the Pfizer Outdo Cancer app, with specific focus on the intro → outro → intro transition path. The goal is to ensure reliable tracking resets between immersive spaces.

## Current Issues

1. **Second Viewing Failure**
   - Tracking sessions do not fully reset after outro phase
   - Hand tracking fails to initialize on subsequent intro views
   - Device anchors become unavailable after immersive space dismissal

2. **State Management Issues**
   - Incomplete cleanup during background/active transitions
   - Race conditions between tracking cleanup and initialization
   - Inadvertent reuse of stopped providers

## Implementation Requirements

### 1. TrackingSessionManager Updates

```swift
final class TrackingSessionManager {
    private var currentSession: ARKitSession?
    private var worldTrackingProvider: WorldTrackingProvider?
    private var handTrackingProvider: HandTrackingProvider?
    
    enum TrackingError: Error {
        case timeoutWaitingForTracking
        case failedToStop
        case failedToStart
        case providerNotAvailable
    }
    
    func startTracking(needsHandTracking: Bool) async throws {
        // 1. Ensure previous session is fully stopped
        if currentSession != nil {
            try await stopTracking()
            try await Task.sleep(for: .milliseconds(100))
            
            // Verify stopped state
            if case .running = worldTrackingProvider?.state {
                throw TrackingError.failedToStop
            }
        }
        
        // 2. Create fresh instances
        let session = ARKitSession()
        let worldProvider = WorldTrackingProvider()
        var providers: [any ARKitProvider] = [worldProvider]
        
        if needsHandTracking {
            let handProvider = HandTrackingProvider()
            providers.append(handProvider)
            handTrackingProvider = handProvider
        }
        
        // 3. Store references BEFORE running
        currentSession = session
        worldTrackingProvider = worldProvider
        
        // 4. Start new session
        do {
            try await session.run(providers)
            Logger.debug("✅ Tracking session started successfully")
            
            // 5. Verify provider state
            try await waitForTrackingToRun()
        } catch {
            // Clear references on failure
            currentSession = nil
            worldTrackingProvider = nil
            handTrackingProvider = nil
            throw TrackingError.failedToStart
        }
    }
    
    func stopTracking() async throws {
        guard let session = currentSession else { return }
        
        // 1. Log current state
        Logger.debug("""
        🛑 Stopping tracking session:
        ├─ World Provider State: \(worldTrackingProvider?.state ?? .stopped)
        └─ Hand Provider State: \(handTrackingProvider?.state ?? .stopped)
        """)
        
        // 2. Stop the session
        try await session.stop()
        
        // 3. Clear all references
        leftHandAnchor = nil
        rightHandAnchor = nil
        worldTrackingProvider = nil
        handTrackingProvider = nil
        currentSession = nil
        
        // 4. Wait for cleanup and verify
        try await Task.sleep(for: .milliseconds(100))
        
        Logger.debug("✅ Tracking session stopped successfully")
    }
    
    func waitForTrackingToRun(timeout: TimeInterval = 2.0) async throws {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            if case .running = worldTrackingProvider?.state {
                return
            }
            try await Task.sleep(for: .milliseconds(100))
        }
        throw TrackingError.timeoutWaitingForTracking
    }
    
    func verifyTrackingState() -> Bool {
        guard let worldProvider = worldTrackingProvider else {
            return false
        }
        
        let worldOK = worldProvider.state == .running
        let handOK = handTrackingProvider?.state == .running
        
        Logger.debug("""
        🔍 Tracking State:
        ├─ World Provider: \(worldOK ? "✅" : "❌")
        └─ Hand Provider: \(handOK ?? false ? "✅" : "❌")
        """)
        
        return worldOK
    }
}
```

### 2. AppModel Phase Transition Updates

```swift
extension AppModel {
    @MainActor
    func transitionToPhase(_ newPhase: AppPhase, adcDataModel: ADCDataModel? = nil) async {
        Logger.info("""
        🔄 === PHASE TRANSITION START ===
        ├─ From: \(currentPhase)
        ├─ To: \(newPhase)
        ├─ Current Tracking State: \(trackingManager.worldTrackingProvider?.state ?? .stopped)
        ├─ Has Hand Tracking: \(currentPhase.needsHandTracking)
        └─ Will Need Hand Tracking: \(newPhase.needsHandTracking)
        """)
        
        guard !isTransitioning else {
            Logger.debug("⚠️ Already transitioning, skipping")
            return
        }
        isTransitioning = true
        defer { isTransitioning = false }

        // 1. Stop tracking if needed
        if currentPhase.needsHandTracking {
            do {
                try await trackingManager.stopTracking()
                try await Task.sleep(for: .milliseconds(100))
                
                // Verify tracking stopped
                if case .stopped = trackingManager.worldTrackingProvider?.state {
                    Logger.info("✅ Tracking stopped successfully")
                } else {
                    Logger.error("❌ Failed to stop tracking")
                    throw TrackingSessionManager.TrackingError.failedToStop
                }
            } catch {
                Logger.error("❌ Error stopping tracking: \(error)")
                // Continue with transition, but log the error
            }
        }

        // 2. Pre-load assets with verification
        await preloadAssets(for: newPhase, adcDataModel: adcDataModel)

        // 3. Clean up current phase
        await cleanupCurrentPhase(for: newPhase)
        
        // 4. Set new phase BEFORE starting tracking
        currentPhase = newPhase

        // 5. Start tracking if needed
        if newPhase.needsHandTracking {
            var trackingStarted = false
            let maxRetries = 3
            
            for attempt in 1...maxRetries {
                do {
                    try await trackingManager.startTracking(needsHandTracking: true)
                    try await trackingManager.waitForTrackingToRun()
                    trackingStarted = true
                    Logger.info("✅ Tracking started successfully on attempt \(attempt)")
                    break
                } catch {
                    Logger.error("❌ Tracking start attempt \(attempt) failed: \(error)")
                    if attempt < maxRetries {
                        try? await Task.sleep(for: .milliseconds(100))
                    }
                }
            }
            
            if !trackingStarted {
                Logger.error("❌ Failed to start tracking after \(maxRetries) attempts")
                await handleTrackingFailure()
            }
        }
        
        // 6. Verify final state
        if !await verifyPhaseConsistency() {
            Logger.error("❌ Phase consistency check failed after transition")
            // Consider recovery options
        }
    }
    
    func verifyPhaseConsistency() async -> Bool {
        // 1. Verify space state
        let spaceStateOK = (currentPhase.needsImmersiveSpace && immersiveSpaceState == .open) ||
                          (!currentPhase.needsImmersiveSpace && immersiveSpaceState == .closed)
        
        // 2. Verify tracking state
        let trackingStateOK = await verifyTrackingState()
        
        Logger.debug("""
        🔍 Phase Consistency Check:
        ├─ Space State: \(spaceStateOK ? "✅" : "❌")
        └─ Tracking State: \(trackingStateOK ? "✅" : "❌")
        """)
        
        return spaceStateOK && trackingStateOK
    }
}
```

### 3. Scene Phase Handling

```swift
// In PfizerOutdoCancerApp
.onChange(of: scenePhase) { _, newPhase in
    switch newPhase {
    case .background:
        Task {
            // 1. Stop tracking first
            try? await appModel.trackingManager.stopTracking()
            
            // 2. Then cleanup app state
            await cleanupAppState()
            
            // 3. Clear game state if needed
            if appModel.currentPhase == .playing {
                await appModel.gameState.tearDownGame()
            }
        }
    case .active:
        Task {
            // 1. Ensure previous cleanup is complete
            try? await Task.sleep(for: .milliseconds(200))
            
            // 2. Reset to intro with fresh tracking
            await appModel.transitionToPhase(.intro, adcDataModel: adcDataModel)
        }
    default:
        break
    }
}
```

## Testing Requirements

1. **Critical Path Testing**
   - Test intro → outro → intro transition specifically
   - Verify tracking state after each phase change
   - Ensure hand tracking works on subsequent views

2. **State Verification**
   - Verify provider states during transitions
   - Check immersive space state consistency
   - Monitor for stopped provider errors

3. **Error Recovery**
   - Test tracking initialization failures
   - Verify cleanup on interruptions
   - Check retry logic effectiveness

## Success Metrics

1. Successful tracking initialization on subsequent intro views
2. No hand tracking failures after outro → intro transition
3. Clean tracking state after immersive space dismissal
4. No "stopped provider" errors in logs
5. Consistent device anchor availability

## Implementation Order

1. Update TrackingSessionManager
   - [ ] Implement new provider management
   - [ ] Add state verification
   - [ ] Improve error handling

2. Update AppModel
   - [ ] Enhance phase transitions
   - [ ] Add consistency checks
   - [ ] Implement retry logic

3. Test and Verify
   - [ ] Test intro → outro → intro path
   - [ ] Verify tracking states
   - [ ] Check error handling 