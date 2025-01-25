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
        #if targetEnvironment(simulator)
        // Do nothing in simulator
        print("⚠️ Hand tracking not available in simulator")
        return
        #else
        // If already tracking with the same hand tracking state, do nothing
        if isTracking && shouldProcessHandTracking == needsHandTracking {
            return
        }
        
        // Wait for previous session to fully stop
        if isTracking {
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
        } else {
            shouldProcessHandTracking = false
            providers = [worldTrackingProvider]
        }
        
        providersStoppedWithError = false
        try await arkitSession.run(providers)
        isTracking = true
        print("✅ Started tracking providers")
        #endif
    }
    
    func stopTracking() {
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
        #if targetEnvironment(simulator)
        // Do nothing in simulator
        return
        #else
        guard shouldProcessHandTracking else { return }
        
        print("🖐️ Starting hand tracking updates")
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
