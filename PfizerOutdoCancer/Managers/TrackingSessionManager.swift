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
    }
    
    func stopTracking() {
        arkitSession.stop()
        isTracking = false
        print("⏹️ Stopped tracking providers")
    }
    
    // MARK: - Update Processing
    func processWorldTrackingUpdates() async {
        for await _ in worldTrackingProvider.anchorUpdates {
            // Process world tracking updates
        }
    }
    
    func processHandTrackingUpdates() async {
        guard shouldProcessHandTracking else { return }
        
        print("🖐️ Starting hand tracking updates")
        for await update in handTrackingProvider.anchorUpdates {
            let handAnchor = update.anchor
            switch update.event {
            case .added, .updated:
                switch handAnchor.chirality {
                case .left:
                    leftHandAnchor = handAnchor
//                    print("👈 Left hand updated")
                case .right:
                    rightHandAnchor = handAnchor
//                    print("👉 Right hand updated")
                }
                // Update the HandTrackingManager with the new anchors
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
                // Update the HandTrackingManager with the removed anchors
                handTrackingManager.updateHandAnchors(left: leftHandAnchor, right: rightHandAnchor)
            }
        }
    }
    
    // MARK: - Event Monitoring
    func monitorTrackingEvents() async {
        for await event in arkitSession.events {
            switch event {
            case .dataProviderStateChanged(_, let newState, let error):
                print("🔄 Provider state changed to: \(newState)")
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
