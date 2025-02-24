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
        Logger.info("\n=== TRACKING SESSION START ===")
        await logTrackingState(context: "Start Tracking Request")
        
        // If already tracking with the same state, skip starting a new session.
        if isTracking && shouldProcessHandTracking == needsHandTracking {
            Logger.debug("""
            === TRACKING SESSION STATUS ===
            ├─ Already tracking with same state - skipping
            """)
            await logTrackingState(context: "Skipped Start (Already Tracking)")
            return
        }
        
        // If already tracking, stop the previous session and verify cleanup
        if isTracking {
            Logger.debug("""
            === TRACKING SESSION STATUS ===
            ├─ Stopping previous tracking session
            """)
            await stopTracking()
            do {
                try await waitForCleanup()
                if !verifyProviderState(expectRunning: false) {
                    Logger.error("""
                    === TRACKING ERROR ===
                    ├─ Provider cleanup failed
                    """)
                    throw TrackingError.cleanupFailed
                }
            } catch {
                Logger.error("""
                === TRACKING ERROR ===
                ├─ Cleanup failed: \(error)
                """)
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
            === TRACKING SESSION STATUS ===
            ├─ Starting tracking (World + Hand)
            """)
        } else {
            shouldProcessHandTracking = false
            providers = [worldTrackingProvider]
            Logger.info("""
            === TRACKING SESSION STATUS ===
            ├─ Starting tracking (World only)
            """)
        }
        
        providersStoppedWithError = false
        
        do {
            // For VisionOS, simply run the ARKit session with the providers.
            try await arkitSession.run(providers)
            
            // Wait for and verify running state
            try await waitForTrackingToRun()
            if !verifyProviderState(expectRunning: true) {
                Logger.error("""
                === TRACKING ERROR ===
                ├─ Provider state verification failed after start
                """)
                throw TrackingError.failedToStart
            }
            
            isTracking = true
            await logTrackingState(context: "Post-Start")
        } catch {
            Logger.error("""
            === TRACKING ERROR ===
            ├─ Failed to start tracking - \(error)
            """)
            isTracking = false
            throw TrackingError.failedToStart
        }
    }
    
    func stopTracking() async {
        Logger.info("\n=== TRACKING SESSION STOP ===")
        arkitSession.stop()
        isTracking = false
        
        // Reinitialize arkitSession to clear any stale state.
        arkitSession = ARKitSession()
        
        // Wait for cleanup
        do {
            try await waitForCleanup()
        } catch {
            Logger.error("""
            === TRACKING ERROR ===
            ├─ Cleanup timeout - \(error)
            """)
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
        === PROVIDER STATE VERIFICATION ===
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
        Logger.debug("""
        === HAND TRACKING UPDATES ===
        ├─ Should Process: \(shouldProcessHandTracking)
        └─ Provider State: \(handTrackingProvider?.state ?? DataProviderState.initialized)
        """)
        
        guard shouldProcessHandTracking else {
            Logger.debug("Hand tracking updates disabled")
            return
        }
        
        Logger.debug("Starting hand tracking updates")
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
                    Logger.debug("Left hand removed")
                case .right:
                    rightHandAnchor = nil
                    Logger.debug("Right hand removed")
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
                // Log detailed state at debug level
                await logTrackingState(context: "Provider State Change [\(newState)]")
                
                // Only log significant state changes at info level
                switch newState {
                case .running:
                    Logger.info("""
                    === TRACKING ACTIVE ===
                    """)
                case .stopped:
                    if let error = error {
                        Logger.error("""
                        === TRACKING ERROR ===
                        ├─ \(error.localizedDescription)
                        """)
                        providersStoppedWithError = true
                    } else {
                        Logger.info("""
                        === TRACKING STOPPED ===
                        """)
                    }
                    isTracking = false
                default:
                    Logger.debug("Tracking state: \(newState)")
                }
                
                currentState = newState
                
            case .authorizationChanged(let type, let status):
                if type == .worldSensing {
                    worldSensingAuthorizationStatus = status
                    if status != .allowed {
                        Logger.error("""
                        === TRACKING AUTHORIZATION ERROR ===
                        ├─ World sensing not authorized: \(status)
                        """)
                    }
                }
            }
        }
    }
    
    func logTrackingState(context: String) async {
        Logger.debug("""
        === TRACKING STATE [\(context)] ===
        ├─ Tracking Enabled: \(isTracking)
        ├─ Hand Tracking Enabled: \(shouldProcessHandTracking)
        └─ Current Provider State: \(currentState)
        """)
        
        if let deviceAnchor = worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) {
            Logger.debug("""
            === DEVICE ANCHOR INFO ===
            ├─ Head Transform: \(deviceAnchor.originFromAnchorTransform)
            ├─ Position X: \(deviceAnchor.originFromAnchorTransform.columns.3.x)
            ├─ Position Y: \(deviceAnchor.originFromAnchorTransform.columns.3.y)
            └─ Position Z: \(deviceAnchor.originFromAnchorTransform.columns.3.z)
            """)
        }
        
        Logger.debug("""
        === PROVIDER STATES ===
        ├─ World Provider: \(worldTrackingProvider.state)
        ├─ Hand Provider: \(handTrackingProvider?.state ?? DataProviderState.initialized)
        └─ Stopped with Error: \(providersStoppedWithError)
        """)
    }
    
    func logTransition(from: String, to: String) async {
        Logger.info("""
        === PHASE TRANSITION ===
        ├─ From: \(from)
        └─ To: \(to)
        """)
        await logTrackingState(context: "Pre-Transition")
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
    func requestWorldSensingAuthorization() async {
        let authorizationResult = await arkitSession.requestAuthorization(for: [.worldSensing])
        worldSensingAuthorizationStatus = authorizationResult[.worldSensing]!
    }
}
