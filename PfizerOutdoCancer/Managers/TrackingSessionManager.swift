import ARKit
import RealityKit
import SwiftUI

@Observable
@MainActor
final class TrackingSessionManager {
    // MARK: - Properties
    let arkitSession = ARKitSession()
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
    
    // Add HandTrackingManager
    let handTrackingManager: HandTrackingManager
    
    init() {
        handTrackingManager = HandTrackingManager(trackingManager: nil)
        handTrackingManager.configure(with: self)
    }
    
    // MARK: - Session Management
    func startTracking(needsHandTracking: Bool = false) async throws {
        print("\n=== Tracking Session Start ===")
        print("Need Hand Tracking: \(needsHandTracking)")
        print("Current Tracking State: \(isTracking)")
        print("Current Hand Tracking State: \(shouldProcessHandTracking)")
        
        #if targetEnvironment(simulator)
        // Do nothing in simulator
        print("⚠️ Hand tracking not available in simulator")
        return
        #else
        // If already tracking with the same hand tracking state, do nothing
        if isTracking && shouldProcessHandTracking == needsHandTracking {
            print("⚠️ Already tracking with same state - skipping")
            return
        }
        
        // Wait for previous session to fully stop
        if isTracking {
            print("🛑 Stopping previous tracking session")
            stopTracking()
            // Wait for the provider to enter stopped state via monitorTrackingEvents
            for _ in 0..<10 { // Maximum 1 second wait
                if !isTracking {
                    break
                }
                try await Task.sleep(for: .milliseconds(100))
            }
        }
        
        // Create new providers for this session
        worldTrackingProvider = WorldTrackingProvider()
        
        let providers: [any DataProvider]
        if needsHandTracking {
            shouldProcessHandTracking = true
            handTrackingProvider = HandTrackingProvider()
            providers = [worldTrackingProvider, handTrackingProvider]
            print("🖐️ Starting hand tracking session")
            print("Hand Provider State: \(handTrackingProvider.state)")
        } else {
            shouldProcessHandTracking = false
            providers = [worldTrackingProvider]
            print("🌎 Starting world tracking only")
        }
        
        providersStoppedWithError = false
        try await arkitSession.run(providers)
        isTracking = true
        print("✅ Started tracking providers")
        print("Final Hand Tracking State: \(shouldProcessHandTracking)")
        #endif
    }
    
    func stopTracking() {
        print("\n=== Stopping Tracking Session ===")
        print("Was Tracking: \(isTracking)")
        print("Had Hand Tracking: \(shouldProcessHandTracking)")
        
        #if targetEnvironment(simulator)
        // Do nothing in simulator
        return
        #else
        arkitSession.stop()
        isTracking = false
        print("⏹️ Stopped tracking providers")
        #endif
    }
    
    // MARK: - Update Processing
    func processWorldTrackingUpdates() async {
        #if targetEnvironment(simulator)
        // Do nothing in simulator
        return
        #else
        for await _ in worldTrackingProvider.anchorUpdates {
            // Process world tracking updates
        }
        #endif
    }
    
    func processHandTrackingUpdates() async {
        print("\n=== Processing Hand Updates ===")
        print("Should Process Hand Tracking: \(shouldProcessHandTracking)")
        print("Hand Provider State: \(handTrackingProvider?.state ?? .initialized)")
        
        #if targetEnvironment(simulator)
        // Do nothing in simulator
        return
        #else
        guard shouldProcessHandTracking else {
            print("❌ Hand tracking updates disabled")
            return
        }
        
        print("🖐️ Starting hand tracking updates")
        for await update in handTrackingProvider.anchorUpdates {
            let handAnchor = update.anchor
            switch update.event {
            case .added, .updated:
                switch handAnchor.chirality {
                case .left:
                    leftHandAnchor = handAnchor
                    print("👈 Left hand \(update.event == .added ? "added" : "updated")")
                case .right:
                    rightHandAnchor = handAnchor
                    print("👉 Right hand \(update.event == .added ? "added" : "updated")")
                }
                handTrackingManager.updateHandAnchors(left: leftHandAnchor, right: rightHandAnchor)
            case .removed:
                switch handAnchor.chirality {
                case .left:
                    leftHandAnchor = nil
                    print("❌ Left hand removed")
                case .right:
                    rightHandAnchor = nil
                    print("❌ Right hand removed")
                }
                handTrackingManager.updateHandAnchors(left: leftHandAnchor, right: rightHandAnchor)
            }
        }
        #endif
    }
    
    // MARK: - Event Monitoring
    func monitorTrackingEvents() async {
        for await event in arkitSession.events {
            switch event {
            case .dataProviderStateChanged(_, let newState, let error):
                print("🔄 Provider state changed to: \(newState)")
                currentState = newState  // Track the current state
                switch newState {
                case .initialized:
                    print("ℹ️ Provider initialized")
                case .running:
                    print("✅ Provider running")
                    isTracking = true
                case .paused:
                    print("⏸️ Provider paused")
                case .stopped:
                    print("⚠️ Provider stopped - Error: \(String(describing: error))")
                    isTracking = false
                    if let error {
                        print("❌ Provider error: \(error)")
                        providersStoppedWithError = true
                    }
                @unknown default:
                    break
                }
            case .authorizationChanged(let type, let status):
                if type == .worldSensing {
                    worldSensingAuthorizationStatus = status
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
        case capabilitiesUnavailable(String)
        case providerError(Error)
        case authorizationDenied
    }
} 
