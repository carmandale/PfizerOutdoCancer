//
//  TrackingSessionManager.swift
//  VisionOS Only – Revised for clean session restarts
//

import ARKit
import RealityKit
import SwiftUI
import QuartzCore

@Observable
@MainActor
final class TrackingSessionManager {
    // MARK: - Properties
    // Making this a variable so we can reinitialize it on stop.
    var arkitSession = ARKitSession()
    var worldTrackingProvider = WorldTrackingProvider()
    var handTrackingProvider: HandTrackingProvider!
    
    private(set) var providersStoppedWithError = false
    private(set) var worldSensingAuthorizationStatus = ARKitSession.AuthorizationStatus.notDetermined
    private var isTracking = false
    
    // Track current provider state
    private(set) var currentState: DataProviderState = .initialized
    
    // Hand tracking state
    private(set) var leftHandAnchor: HandAnchor?
    private(set) var rightHandAnchor: HandAnchor?
    var shouldProcessHandTracking: Bool = false
    
    // HandTrackingManager
    let handTrackingManager: HandTrackingManager
    
    // Weak reference to AppModel
    weak var appModel: AppModel?
    
    init() {
        handTrackingManager = HandTrackingManager(trackingManager: nil)
        handTrackingManager.configure(with: self)
    }
    
    // MARK: - Session Management
    func startTracking(needsHandTracking: Bool = false) async throws {
        await logTrackingState(context: "Start Tracking Request")
        
        // Check for simulator environment
        #if targetEnvironment(simulator)
        Logger.info("""
        
        === TRACKING SESSION IN SIMULATOR ===
        ├─ Detected simulator environment
        ├─ Using fallback positioning instead of active tracking
        """)
        // Just mark tracking as active without starting real tracking
        worldTrackingProvider = WorldTrackingProvider()
        if needsHandTracking {
            handTrackingProvider = HandTrackingProvider()
            shouldProcessHandTracking = true
        }
        currentState = .running
        isTracking = true
        return
        #endif
        
        // If already tracking with the same state, skip starting a new session.
        if isTracking && shouldProcessHandTracking == needsHandTracking {
            Logger.info("⚠️ Already tracking with same state - skipping")
            await logTrackingState(context: "Skipped Start (Already Tracking)")
            return
        }
        
        // If already tracking, stop the previous session and verify cleanup
        if isTracking {
            Logger.info("🛑 Stopping previous tracking session")
            await stopTracking()
            do {
                try await waitForCleanup()
                if !verifyProviderState(expectRunning: false) {
                    Logger.error("❌ Provider state verification failed after cleanup")
                    throw TrackingError.cleanupFailed
                }
            } catch {
                Logger.error("❌ Cleanup failed: \(error)")
                throw TrackingError.cleanupFailed
            }
            await logTrackingState(context: "Post-Stop Check")
        }
        
        // Reinitialize providers to guarantee fresh state.
        worldTrackingProvider = WorldTrackingProvider()
        let providers: [any DataProvider]
        if needsHandTracking {
            shouldProcessHandTracking = true
            handTrackingProvider = HandTrackingProvider()
            providers = [worldTrackingProvider, handTrackingProvider]
            Logger.info("""
            
            🖐️ Configuring Tracking Session
            ├─ World Tracking: Enabled
            ├─ Hand Tracking: Enabled
            ├─ Provider State: \(currentState)
            └─ Previous Tracking: \(isTracking ? "Active" : "Inactive")
            """)
        } else {
            shouldProcessHandTracking = false
            providers = [worldTrackingProvider]
            Logger.info("""
            
            🌎 Configuring Tracking Session
            ├─ World Tracking: Enabled
            ├─ Hand Tracking: Disabled
            ├─ Provider State: \(currentState)
            └─ Previous Tracking: \(isTracking ? "Active" : "Inactive")
            """)
        }
        
        providersStoppedWithError = false
        
        do {
            // For VisionOS, simply run the ARKit session with the providers.
            try await arkitSession.run(providers)
            
            // Wait for and verify running state
            try await waitForTrackingToRun()
            if !verifyProviderState(expectRunning: true) {
                Logger.error("❌ Provider state verification failed after start")
                throw TrackingError.failedToStart
            }
            
            isTracking = true
            await logTrackingState(context: "Post-Start")
        } catch {
            Logger.error("❌ Failed to start tracking: \(error)")
            isTracking = false
            throw TrackingError.failedToStart
        }
    }
    
    func stopTracking() async {
        Logger.info("🛑 Stopping Tracking Session")
        arkitSession.stop()
        isTracking = false
        
        // Reinitialize arkitSession to clear any stale state.
        arkitSession = ARKitSession()
        
        // Wait for cleanup
        do {
            try await waitForCleanup()
        } catch {
            Logger.error("❌ Cleanup timeout: \(error)")
        }
        
        await logTrackingState(context: "Post-Stop")
    }
    
    func waitForTrackingToRun(timeout: TimeInterval = 2.0) async throws {
        let startTime = Date()
        while true {
            if case .running = self.worldTrackingProvider.state {
                return
            }
            if Date().timeIntervalSince(startTime) > timeout {
                throw TrackingError.timedOut
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
        }
    }
    
    /// Waits for tracking providers to reach a stopped state
    /// - Parameter timeout: Maximum time to wait for cleanup (default: 1.0 seconds)
    /// - Throws: TrackingError.cleanupTimeout if providers don't stop within timeout
    func waitForCleanup(timeout: TimeInterval = 1.0) async throws {
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            if case .stopped = worldTrackingProvider.state {
                if !shouldProcessHandTracking || handTrackingProvider?.state == .stopped {
                    return
                }
            }
            try await Task.sleep(for: .milliseconds(50))
        }
        throw TrackingError.cleanupTimeout
    }
    
    /// Verifies the current state of tracking providers
    /// - Parameter expectRunning: Whether providers should be in running state
    /// - Returns: true if providers are in expected state
    func verifyProviderState(expectRunning: Bool) -> Bool {
        let worldState = worldTrackingProvider.state
        let handState = handTrackingProvider?.state
        
        let worldOK = expectRunning ? worldState == .running : worldState == .stopped
        let handOK = !shouldProcessHandTracking || 
                    (expectRunning ? handState == .running : handState == .stopped)
        
        Logger.debug("""
        🔍 Provider State Verification
        ├─ Expected State: \(expectRunning ? "Running" : "Stopped")
        ├─ World Provider: \(worldOK ? "✅" : "❌") [\(worldState)]
        ├─ Hand Tracking Needed: \(shouldProcessHandTracking)
        └─ Hand Provider: \(handOK ? "✅" : "❌") [\(handState ?? .stopped)]
        """)
        
        return worldOK && handOK
    }
    
    // MARK: - Update Processing
    func processWorldTrackingUpdates() async {
        for await _ in worldTrackingProvider.anchorUpdates {
            // Process world tracking updates.
        }
    }
    
    func processHandTrackingUpdates() async {
        Logger.info("""
        
        === Processing Hand Updates ===
        ├─ Should Process Hand Tracking: \(shouldProcessHandTracking)
        └─ Hand Provider State: \(handTrackingProvider?.state ?? DataProviderState.initialized)
        """)
        
        guard shouldProcessHandTracking else {
            Logger.info("❌ Hand tracking updates disabled")
            return
        }
        
        Logger.info("🖐️ Starting hand tracking updates")
        for await update in handTrackingProvider.anchorUpdates {
            let handAnchor = update.anchor
            switch update.event {
            case .added, .updated:
                switch handAnchor.chirality {
                case .left:
                    leftHandAnchor = handAnchor
                case .right:
                    rightHandAnchor = handAnchor
                }
                handTrackingManager.updateHandAnchors(left: leftHandAnchor, right: rightHandAnchor)
            case .removed:
                switch handAnchor.chirality {
                case .left:
                    leftHandAnchor = nil
                    Logger.info("❌ Left hand removed")
                case .right:
                    rightHandAnchor = nil
                    Logger.info("❌ Right hand removed")
                }
                handTrackingManager.updateHandAnchors(left: leftHandAnchor, right: rightHandAnchor)
            }
        }
    }
    
    // MARK: - Event Monitoring
    func monitorTrackingEvents() async {
        for await event in arkitSession.events {
            switch event {
            case .dataProviderStateChanged(let providers, let newState, let error):
                for provider in providers {
                    let providerName: String
                    if provider is WorldTrackingProvider {
                        providerName = "World Tracking"
                    } else if provider is HandTrackingProvider {
                        providerName = "Hand Tracking"
                    } else {
                        providerName = "Unknown"
                    }
                    
                    Logger.info("""
                    
                    🔄 Provider State Change
                    ├─ Provider: \(providerName)
                    ├─ From: \(currentState)
                    ├─ To: \(newState)
                    ├─ Error: \(error?.localizedDescription ?? "none")
                    └─ Current Phase: \(appModel?.currentPhase ?? .loading)
                    """)
                }
                
                currentState = newState
                await logTrackingState(context: "Provider State Change [\(newState)]")
                
                switch newState {
                case .initialized:
                    Logger.info("ℹ️ Providers initialized")
                case .running:
                    Logger.info("✅ Providers running")
                    isTracking = true
                case .paused:
                    Logger.info("⏸️ Providers paused")
                case .stopped:
                    if let error = error {
                        Logger.info("""
                        
                        ❌ Providers Stopped with Error
                        ├─ Error: \(error)
                        └─ State: \(currentState)
                        """)
                        providersStoppedWithError = true
                    } else {
                        Logger.info("""
                        
                        ⏹️ Providers Stopped Normally
                        └─ State: \(currentState)
                        """)
                    }
                    isTracking = false
                @unknown default:
                    break
                }
                
            case .authorizationChanged(let type, let status):
                if type == .worldSensing {
                    worldSensingAuthorizationStatus = status
                    Logger.info("""
                    
                    🔐 Authorization Changed
                    ├─ Type: World Sensing
                    └─ Status: \(status)
                    """)
                }
                
            default:
                break
            }
        }
    }
    
    // MARK: - Authorization
    func requestWorldSensingAuthorization() async {
        let authorizationResult = await arkitSession.requestAuthorization(for: [.worldSensing])
        worldSensingAuthorizationStatus = authorizationResult[.worldSensing]!
    }
}

// MARK: - Errors
extension TrackingSessionManager {
    enum TrackingError: Error {
        case timedOut
        case cleanupTimeout
        case failedToStop
        case failedToStart
        case providerNotAvailable
        case invalidState
        case cleanupFailed
    }
}

// MARK: - Enhanced Logging
extension TrackingSessionManager {
    func logTrackingState(context: String) async {
        // Check if detailed tracking logs are enabled
        guard Logger.shouldLogTracking() else {
            // If detailed tracking is disabled, just log a simplified state
            if context.contains("Error") || providersStoppedWithError {
                Logger.error("⚠️ Tracking error detected: \(context)")
            }
            return
        }
        
        // Use verbose level for the most detailed tracking info
        Logger.verbose("""
        
        === Tracking State [\(context)] ===
        ├─ Tracking Enabled: \(isTracking)
        ├─ Hand Tracking Enabled: \(shouldProcessHandTracking)
        └─ Current Provider State: \(currentState)
        """)
        
        // Only log device anchor details at verbose level
        if let deviceAnchor = worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) {
            Logger.verbose("""
            
            📍 Device Anchor Info
            ├─ Head Transform: \(deviceAnchor.originFromAnchorTransform)
            ├─ Position X: \(deviceAnchor.originFromAnchorTransform.columns.3.x)
            ├─ Position Y: \(deviceAnchor.originFromAnchorTransform.columns.3.y)
            └─ Position Z: \(deviceAnchor.originFromAnchorTransform.columns.3.z)
            """)
        } else {
            Logger.debug("⚠️ No device anchor available")
        }
        
        // Log provider states at debug level for troubleshooting
        let allProvidersRunning = worldTrackingProvider.state == .running && 
                                 (handTrackingProvider?.state ?? .running) == .running
        
        Logger.debug("""
        
        🌐 Provider States
        ├─ World Provider: \(worldTrackingProvider.state)
        ├─ Hand Provider: \(handTrackingProvider?.state ?? DataProviderState.initialized)
        └─ Stopped with Error: \(providersStoppedWithError)
        \(allProvidersRunning ? "✅ Providers running" : "⚠️ Some providers not running")
        """)
    }
    
    func logTransition(from: String, to: String) async {
        Logger.info("""
        
        🔄 Phase Transition
        ├─ From: \(from)
        └─ To: \(to)
        """)
        // Only log tracking state during transitions if tracking logs are enabled
        if Logger.shouldLogTracking() {
            await logTrackingState(context: "Pre-Transition")
        }
    }
}
