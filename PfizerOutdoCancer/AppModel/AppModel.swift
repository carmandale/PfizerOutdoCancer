import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

// MARK: - App Constants
extension AppModel {
    nonisolated static let mainWindowId = "main"
    nonisolated static let introWindowId = "intro"
    nonisolated static let libraryWindowId = "library"
    nonisolated static let builderWindowId = "builder"
    nonisolated static let debugNavigationWindowId = "DebugNavigation"
    nonisolated static let gameCompletedWindowId = "Completed"
    
    nonisolated static let introSpaceId = "IntroSpace"
    nonisolated static let outroSpaceId = "OutroSpace"
    nonisolated static let labSpaceId = "LabSpace"
    nonisolated static let buildingSpaceId = "BuildingSpace"
    nonisolated static let attackSpaceId = "AttackSpace"
}

enum AppPhase: String, CaseIterable, Codable, Sendable, Equatable {
    case loading
    case intro
    case lab
    case building
    case playing
    case completed
    case outro
    case error
    
    var needsImmersiveSpace: Bool {
        return self != .loading && self != .error && self != .building
    }
    
    var needsHandTracking: Bool {
        switch self {
        case .playing:
            return true
        case .loading, .intro, .lab, .building, .completed, .outro, .error:
            return false
        }
    }
    
    var shouldKeepPreviousSpace: Bool {
        if self == .completed { return true }
        return false
    }
    
    var spaceId: String {
        switch self {
        case .intro: return AppModel.introSpaceId
        case .lab: return AppModel.labSpaceId
        case .building: return AppModel.buildingSpaceId
        case .playing, .completed: return AppModel.attackSpaceId
        case .outro: return AppModel.outroSpaceId
        case .loading, .error: return ""
        }
    }
    
    var windowId: String {
        switch self {
        case .loading: return AppModel.mainWindowId
        case .intro: return AppModel.introWindowId
        case .completed: return AppModel.gameCompletedWindowId
        case .lab: return AppModel.libraryWindowId
        case .building: return AppModel.builderWindowId
        case .playing, .outro, .error: return ""
        }
    }
}

@Observable
@MainActor
final class AppModel {
    // MARK: - Properties
    /// Current phase of the app
    var currentPhase: AppPhase = .loading
    
    // var adcDataModel: ADCDataModel
    var gameState: AttackCancerViewModel
    var handTracking: HandTrackingViewModel
    var isDebugWindowOpen = false
    var isLibraryWindowOpen = false
    var isIntroWindowOpen = false
    var isMainWindowOpen = false
    var isBuilderInstructionsOpen = false
    var isBuilderWindowOpen = false
    var isLoadingWindowOpen = false

    // MARK: - Immersion Style
    var introStyle: ImmersionStyle = .mixed
    var outroStyle: ImmersionStyle = .mixed
    var labStyle: ImmersionStyle = .full
    var buildingStyle: ImmersionStyle = .mixed
    var attackStyle: ImmersionStyle = .progressive(
        0.1...1.0,
        initialAmount: 0.65
    )

    // MARK: - Asset Management
    let assetLoadingManager = AssetLoadingManager.shared
    var loadingProgress: Float = 0
    var loadingState: LoadingState = .notStarted
    
    enum LoadingState {
        case notStarted
        case loading
        case completed
        case error
        
        var isComplete: Bool {
            if case .completed = self { return true }
            return false
        }
    }

    var headTrackState: HeadTrackState = .headPosition

    /// Track the state of the toggle.
    /// Follow: Uses `queryDeviceAnchor` to follow the device's position.
    /// HeadPosition: Uses `AnchorEntity` to launch at the head position in front of the wearer.
    enum HeadTrackState: String, CaseIterable {
        case follow
        case headPosition = "head-position"
    }
    
    // MARK: - Space Management
    @ObservationIgnored private var currentImmersiveSpace: String?
    @ObservationIgnored private(set) var isTransitioning = false
    
    var hasImmersiveSpace: Bool {
        return currentImmersiveSpace != nil
    }
    
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    
    var immersiveSpaceState: ImmersiveSpaceState = .closed
    
    // MARK: - Hope Meter Management
    @ObservationIgnored private var hopeMeterTimer: Timer?
    
    func startHopeMeter() {
        print("🕒 Starting Hope Meter")
        stopHopeMeter() // Ensure any existing timer is cleaned up
        
        gameState.hopeMeterTimeLeft = gameState.hopeMeterDuration // Reset timer
        gameState.isHopeMeterRunning = true
        
        hopeMeterTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                if self.gameState.hopeMeterTimeLeft > 0 {
                    self.gameState.hopeMeterTimeLeft -= 1
                } else {
                    self.stopHopeMeter()
                    await self.transitionToPhase(.completed)
                }
            }
        }
    }
    
    func stopHopeMeter() {
        print("🛑 Stopping Hope Meter")
        hopeMeterTimer?.invalidate()
        hopeMeterTimer = nil
        gameState.isHopeMeterRunning = false
    }
    
    deinit {
        // Since we're on MainActor, we can directly invalidate the timer
        hopeMeterTimer?.invalidate()
        hopeMeterTimer = nil
    }
    
    // MARK: - Initialization
    init() {
        print("📱 AppModel created with ARKitSession ID: \(arkitSessionId)")
        // self.adcDataModel = ADCDataModel()
        self.handTracking = HandTrackingViewModel()
        self.gameState = AttackCancerViewModel()
        self.gameState.appModel = self
        self.gameState.handTracking = self.handTracking
    }
    
    // MARK: - Phase Management
    @MainActor
    func transitionToPhase(_ newPhase: AppPhase, adcDataModel: ADCDataModel? = nil) async {
        guard !isTransitioning else { 
            print("⚠️ Skipping transition - already in transition")
            return 
        }
        
        isTransitioning = true
        
        // Handle setup if needed
        if newPhase == .playing, let adcDataModel = adcDataModel {
            if let adcEntity = await assetLoadingManager.instantiateEntity("adc") {
                gameState.setADCTemplate(adcEntity, dataModel: adcDataModel)
            }
        }
        
        currentPhase = newPhase
        isTransitioning = false
    }
    
    let trackingManager = TrackingSessionManager()
    
    // Initialize tracking when needed
    @MainActor
    func initializeTracking(content: RealityViewContent) async throws {
        try await trackingManager.initialize(content: content)
    }
    
    // Track if app is active
    var isActive: Bool = true
    
    @MainActor
    func handleScenePhaseChange(_ newPhase: ScenePhase) async {
        switch newPhase {
        case .background, .inactive:
            isActive = false
            if immersiveSpaceState == .open {
                immersiveSpaceState = .inTransition
                currentPhase = .loading
            }
            // await handTracking.stopSession()
            
        case .active:
            isActive = true
            // Show navigation view when returning to foreground
            if !isDebugWindowOpen {
                isDebugWindowOpen = true
                // Note: Actual window opening happens in PfizerOutdoCancerApp 
                // through window binding
            }
            
        @unknown default:
            break
        }
    }
    
    // ARKit Session Management
    let arkitSessionId = UUID()
    let arkitSession = ARKitSession()
    var worldTrackingProvider = WorldTrackingProvider()
    var handTrackingProvider = HandTrackingProvider()
    
    @MainActor
    func runARKitSession() async throws {
        let providers: [any DataProvider] = currentPhase.needsHandTracking ? 
            [worldTrackingProvider, handTrackingProvider] :
            [worldTrackingProvider]
        
        // Run each provider separately
        for provider in providers {
            switch provider.state {
            case .running:
                print("⚠️ Provider \(provider) already running, skipping")
                continue
            case .stopped:
                print("⚠️ Provider \(provider) is stopped, creating new instance")
                // Create new provider instance
                if provider is WorldTrackingProvider {
                    worldTrackingProvider = WorldTrackingProvider()
                    try await arkitSession.run([worldTrackingProvider])
                } else if provider is HandTrackingProvider {
                    handTrackingProvider = HandTrackingProvider()
                    try await arkitSession.run([handTrackingProvider])
                }
            default:
                try await arkitSession.run([provider])
            }
            print("✅ Started provider: \(provider)")
        }
    }
    
    // func stopARKitSession() {
    //     arkitSession.stop()
    //     print("🛑 ARKit session stopped")
    // }
    
    // Monitor session state
    var providersStoppedWithError = false
    
    func monitorSessionEvents() async {
        for await event in arkitSession.events {
            switch event {
            case .dataProviderStateChanged(let provider, let newState, let error):
                print("🔄 Provider \(provider) state changed to: \(newState)")
                switch newState {
                case .initialized:
                    print("ℹ️ Provider initialized")
                case .running:
                    print("✅ Provider running")
                case .paused:
                    print("⏸️ Provider paused")
                    if immersiveSpaceState == .open {
                        providersStoppedWithError = true
                    }
                case .stopped:
                    print("⚠️ Provider \(provider) stopped - Error: \(String(describing: error))")
                    print("📍 Stack trace:")
                    Thread.callStackSymbols.forEach { print($0) }
                    if let error {
                        print("❌ Provider error: \(error)")
                        providersStoppedWithError = true
                    } else {
                        print("⚠️ Provider stopped without error")
                    }
                @unknown default:
                    break
                }
            default:
                break
            }
        }
    }
}
