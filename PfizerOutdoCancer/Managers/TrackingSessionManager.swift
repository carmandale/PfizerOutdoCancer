import ARKit
import RealityKit
import SwiftUI
import QuartzCore

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
        await logTrackingState(context: "Start Tracking Request")
        
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
            await logTrackingState(context: "Post-Stop Check")
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
        
        await logTrackingState(context: "Post-Start")
        #endif
    }
    
    func stopTracking() {
        #if targetEnvironment(simulator)
        // Do nothing in simulator
        return
        #else
        Task {
            await logTrackingState(context: "Pre-Stop")
            
            arkitSession.stop()
            isTracking = false
            
            // Give a moment for state to update
            try? await Task.sleep(for: .milliseconds(100))
            await logTrackingState(context: "Post-Stop")
        }
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
//                    print("👈 Left hand \(update.event == .added ? "added" : "updated")")
                case .right:
                    rightHandAnchor = handAnchor
//                    print("👉 Right hand \(update.event == .added ? "added" : "updated")")
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
                
                // Log full state after any state change
                await logTrackingState(context: "Provider State Change [\(newState)]")
                
                switch newState {
                case .initialized:
                    print("ℹ️ Provider initialized")
                case .running:
                    print("✅ Provider running")
                    isTracking = true
                case .paused:
                    print("⏸️ Provider paused")
                case .stopped:
                    if let error {
                        print("❌ Provider stopped with error: \(error)")
                        providersStoppedWithError = true
                    } else {
                        print("⏹️ Provider stopped normally")
                    }
                    isTracking = false
                @unknown default:
                    break
                }
                
            case .authorizationChanged(let type, let status):
                if type == .worldSensing {
                    worldSensingAuthorizationStatus = status
                    print("🔐 World sensing authorization changed: \(status)")
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

// MARK: - Enhanced Logging
extension TrackingSessionManager {
    /// Logs the current tracking state with detailed position and state information
    /// - Parameter context: A string describing the context of when this log is being made
    func logTrackingState(context: String) async {
        print("\n=== Tracking State [\(context)] ===")
        
        // Log tracking flags
        print("🎯 Tracking Enabled: \(isTracking)")
        print("✋ Hand Tracking Enabled: \(shouldProcessHandTracking)")
        print("🔄 Current Provider State: \(currentState)")
        
        // Get and log head position
        if let deviceAnchor = try? await worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) {
            print("📍 Head Transform: \(deviceAnchor.originFromAnchorTransform)")
            // Extract position components for easier reading
            let position = deviceAnchor.originFromAnchorTransform.columns.3
            print("📍 Head Position - X: \(position.x), Y: \(position.y), Z: \(position.z)")
        } else {
            print("⚠️ No device anchor available")
        }
        
        // Log provider states
        print("🌎 World Provider State: \(worldTrackingProvider.state)")
        if let handState = handTrackingProvider?.state {
            print("🖐️ Hand Provider State: \(handState)")
        }
        
        // Log any error states
        if providersStoppedWithError {
            print("❌ Providers stopped with error")
        }
        
        print("=== End State Log ===\n")
    }
    
    /// Logs the transition between two phases
    /// - Parameters:
    ///   - from: The phase we're transitioning from
    ///   - to: The phase we're transitioning to
    func logTransition(from: String, to: String) async {
        print("\n🔄 === Phase Transition [\(from) -> \(to)] ===")
        await logTrackingState(context: "Pre-Transition")
    }
} 
