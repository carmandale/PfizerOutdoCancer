Below is a refined version of your PRD that aligns with our research and Apple's VisionOS 2 best practices. This document is tailored to your project and focuses solely on ensuring smooth tracking session resets between immersive spaces (especially for the intro → outro → intro transition).

Tracking Session Management Implementation Guide

Overview

This document defines the implementation requirements for handling ARKit tracking sessions in the Pfizer Outdo Cancer app. Our focus is on ensuring that each immersive view (particularly when transitioning from outro back to intro) uses a completely fresh ARKit session with new tracking providers, so that device and hand tracking initialize reliably.

Current Issues
	1.	Second Viewing Failure
	•	Tracking sessions do not fully reset after the outro phase.
	•	Hand tracking fails to initialize on subsequent intro views.
	•	Device anchors become unavailable after immersive space dismissal.
	2.	State Management Issues
	•	Incomplete cleanup during background/active transitions.
	•	Race conditions exist between tracking cleanup and initialization.
	•	Stopped providers are inadvertently reused, leading to errors.

Implementation Requirements

1. TrackingSessionManager Updates

A. Session Initialization
	•	Ensure Full Cleanup:
If a session is already running, call stopTracking() and wait (e.g., 100 ms) to allow complete cleanup. Verify that the previous session's providers have reached a stopped state before proceeding.
	•	Create Fresh Instances:
Always create a new ARKitSession and new instances of the tracking providers (e.g. WorldTrackingProvider and, if needed, HandTrackingProvider). Do not reuse any previously stopped provider.
	•	Start the New Session:
Store the new session and provider references, then start the session with the fresh provider array. If starting the session fails, clear the references and propagate an error.
	•	Verify Tracking State:
After starting, wait for the world tracking provider to report a running state (with a timeout), otherwise throw a timeout error.

Example:

final class TrackingSessionManager {
    private var currentSession: ARKitSession?
    private var worldTrackingProvider: WorldTrackingProvider?
    private var handTrackingProvider: HandTrackingProvider?
    
    enum TrackingError: Error {
        case timeoutWaitingForTracking
        case failedToStop
        case failedToStart
    }
    
    func startTracking(needsHandTracking: Bool) async throws {
        // 1. Ensure previous session is fully stopped
        if currentSession != nil {
            try await stopTracking()
            try await Task.sleep(for: .milliseconds(100))
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
        
        // 4. Start new session and verify provider state
        do {
            try await session.run(providers)
            Logger.debug("✅ Tracking session started successfully")
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
        
        // 4. Wait for cleanup
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

B. Session Cleanup
	•	Stop the session using session.stop().
	•	Clear all anchor and provider references.
	•	Wait briefly (100 ms) to ensure complete cleanup.

2. AppModel Phase Transition Updates

A. Pre-Transition Steps
	•	Stop Tracking:
If the current phase uses hand tracking, call trackingManager.stopTracking() and wait briefly to ensure the session has fully stopped. Verify that the world tracking provider reports a stopped state.
	•	Pre-load Assets & Cleanup:
Pre-load necessary assets and clean up current phase state before starting a new session.

B. Post-Transition Steps
	•	Set New Phase:
Update the current phase before starting the new tracking session.
	•	Start a New Tracking Session:
Call trackingManager.startTracking(needsHandTracking: true) with retry logic (up to 3 attempts). Verify that the new session reaches a running state by using waitForTrackingToRun().
If tracking fails after retries, invoke error recovery.

Example:

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
        
        // 2. Pre-load assets
        await preloadAssets(for: newPhase, adcDataModel: adcDataModel)
        
        // 3. Clean up current phase
        await cleanupCurrentPhase(for: newPhase)
        
        // 4. Set new phase BEFORE starting tracking
        currentPhase = newPhase
        
        // 5. Start tracking if needed with retry logic
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
        
        // 6. Verify final state consistency
        if !await verifyPhaseConsistency() {
            Logger.error("❌ Phase consistency check failed after transition")
            // Optionally trigger recovery
        }
    }
    
    func verifyPhaseConsistency() async -> Bool {
        let spaceStateOK = (currentPhase.needsImmersiveSpace && immersiveSpaceState == .open) ||
                           (!currentPhase.needsImmersiveSpace && immersiveSpaceState == .closed)
        let trackingStateOK = await trackingManager.verifyTrackingState()
        Logger.debug("""
        🔍 Phase Consistency Check:
        ├─ Space State: \(spaceStateOK ? "✅" : "❌")
        └─ Tracking State: \(trackingStateOK ? "✅" : "❌")
        """)
        return spaceStateOK && trackingStateOK
    }
}

C. Error Recovery

Implement a method to handle tracking failures by stopping the session, waiting for cleanup, and then attempting to restart tracking.

func handleTrackingFailure() async {
    Logger.error("🚨 Tracking failure detected")
    await trackingManager.stopTracking()
    try? await Task.sleep(for: .milliseconds(200))
    do {
        try await trackingManager.startTracking(needsHandTracking: currentPhase.needsHandTracking)
    } catch {
        Logger.error("❌ Recovery failed: \(error)")
        await transitionToPhase(.error)
    }
}

3. Scene Phase Handling

Ensure the app cleans up tracking when transitioning to background and restarts tracking when returning to active mode.

Example:

.onChange(of: scenePhase) { _, newPhase in
    switch newPhase {
    case .background:
        Task {
            try? await appModel.trackingManager.stopTracking()
            await cleanupAppState()
            if appModel.currentPhase == .playing {
                await appModel.gameState.tearDownGame()
            }
        }
    case .active:
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            await appModel.transitionToPhase(.intro, adcDataModel: adcDataModel)
        }
    default:
        break
    }
}

4. Immersive Space Management

Ensure that when dismissing an immersive space, tracking is stopped and state is reset.

Example:

func cleanupAppState() async {
    appModel.immersiveSpaceDismissReason = .manual
    if appModel.immersiveSpaceState == .open {
        await dismissImmersiveSpace()
        try? await appModel.trackingManager.stopTracking()
        try? await Task.sleep(for: .milliseconds(50))
        appModel.immersiveSpaceState = .closed
        appModel.immersiveSpaceDismissReason = nil
    }
}

5. State Verification Methods

Add helper methods to verify that the tracking and phase states are consistent.

extension AppModel {
    func verifyTrackingState() async -> Bool {
        let needsTracking = currentPhase.needsHandTracking
        let worldOK = trackingManager.worldTrackingProvider?.state == .running
        let handOK = !needsTracking || (trackingManager.handTrackingProvider?.state == .running)
        Logger.debug("Tracking State Verification: needsTracking = \(needsTracking), worldOK = \(String(describing: worldOK)), handOK = \(String(describing: handOK))")
        return worldOK && handOK
    }
    
    func verifyPhaseConsistency() async -> Bool {
        let spaceStateOK = (currentPhase.needsImmersiveSpace && immersiveSpaceState == .open) ||
                           (!currentPhase.needsImmersiveSpace && immersiveSpaceState == .closed)
        let trackingStateOK = await verifyTrackingState()
        return spaceStateOK && trackingStateOK
    }
}

Testing Requirements
	1.	Critical Path Testing
	•	Test the intro → outro → intro transition path.
	•	Verify that after each transition, the new ARKitSession is fresh and device anchors are available.
	•	Confirm that hand tracking initializes reliably on subsequent views.
	2.	State Verification
	•	Validate that all provider states (world and hand) are correct during and after transitions.
	•	Monitor logs for "stopped provider" errors and ensure none occur.
	3.	Error Recovery
	•	Simulate tracking initialization failures to test the retry and recovery logic.
	•	Test background/foreground transitions to verify proper session teardown and restart.

Success Metrics
	1.	Consistent Tracking Initialization:
Every new immersive view (after outro) starts with a fresh ARKitSession and new tracking providers.
	2.	No Provider Reuse Errors:
Logs do not show "stopped provider" errors or attempts to reuse old providers.
	3.	Reliable Hand Tracking:
Hand tracking and device anchors (for head tracking) are consistently available on each transition.
	4.	Smooth Phase Transitions:
The app stops tracking, cleans up state, and starts a new session reliably without race conditions.
	5.	Robust Error Recovery:
In cases of tracking initialization failure, the app's recovery logic successfully resets the session and reinitializes tracking.

Implementation Order

1. TrackingSessionManager Updates (Phase 1)
   a. Session Cleanup Enhancement
      - Add verifyProviderState() method to check provider states
      - Implement waitForCleanup() with timeout for session stop
      - Add comprehensive logging for provider state changes
   
   b. Session Initialization Hardening
      - Add pre-start verification checks
      - Implement provider creation with state verification
      - Add retry logic with proper delays

   Example Implementation Priority:
   ```swift
   // 1. Add these methods first
   func verifyProviderState() -> Bool {
       guard let worldProvider = worldTrackingProvider else { return false }
       return worldProvider.state == .running &&
              (!currentPhase.needsHandTracking || handTrackingProvider?.state == .running)
   }

   func waitForCleanup(timeout: TimeInterval = 1.0) async throws {
       let start = Date()
       while Date().timeIntervalSince(start) < timeout {
           if worldTrackingProvider?.state == .stopped {
               return
           }
           try await Task.sleep(for: .milliseconds(50))
       }
       throw TrackingError.cleanupTimeout
   }
   ```

2. AppModel Phase Transition Updates (Phase 2)
   a. Critical Path Focus
      - Implement outro → intro transition handler first
      - Add state verification before and after transition
      - Implement retry logic for tracking initialization

   Example Implementation Priority:
   ```swift
   // 1. Add this method first
   func handleOutroToIntroTransition() async throws {
       // 1. Stop current tracking
       try await trackingManager.stopTracking()
       try await trackingManager.waitForCleanup()
       
       // 2. Verify cleanup
       guard trackingManager.verifyProviderState() == false else {
           throw TransitionError.cleanupFailed
       }
       
       // 3. Start new tracking
       try await startTrackingWithRetry()
   }
   ```

3. Testing Focus (Phase 3)
   a. Specific Test Scenarios
      1. Basic Transition Test
         - Start app → Enter intro space → Exit to outro → Re-enter intro
         - Verify hand tracking works at each step
         - Check logs for proper cleanup between transitions

      2. Error Recovery Test
         - Force tracking failure during transition
         - Verify retry logic works
         - Confirm error logging is helpful

      3. State Consistency Test
         - Check provider states during transitions
         - Verify no stopped providers are reused
         - Confirm proper cleanup timing

Success Metrics (Specific and Measurable)

1. Transition Reliability
   - 100% success rate for outro → intro transitions
   - No "stopped provider" errors in logs
   - Hand tracking available within 2 seconds of intro space entry

2. Error Recovery
   - Successful recovery from tracking failures within 3 retry attempts
   - Clear error logs showing the failure reason
   - Proper state cleanup after failed attempts

3. Performance
   - Transition time under 3 seconds total
   - No UI freezes during tracking initialization
   - Memory usage stable across transitions

Implementation Checklist

Phase 1: TrackingSessionManager
- [ ] Add verifyProviderState() method
- [ ] Implement waitForCleanup()
- [ ] Add comprehensive logging
- [ ] Test cleanup reliability
- [ ] Implement retry logic

Phase 2: AppModel
- [ ] Add outro → intro specific handler
- [ ] Implement state verification
- [ ] Add transition logging
- [ ] Test transition reliability

Phase 3: Testing
- [ ] Create test scenarios
- [ ] Implement logging analysis
- [ ] Verify success metrics
- [ ] Document any remaining issues

Next Steps:
1. Start with TrackingSessionManager updates
2. Create test scenarios for verification
3. Implement AppModel changes
4. Validate against success metrics

References
	•	Apple VisionOS Documentation
	•	WWDC sessions on RealityKit and SpatialTrackingSession
	•	Developer forums and sample code on ARKit session resets and provider reuse

This PRD now precisely defines what needs to be done to reliably reset tracking between immersive spaces, and it aligns with Apple's visionOS 2 best practices. Let me know if any further adjustments or clarifications are needed!