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
    nonisolated static let hopeMeterUtilityWindowId = "HopeMeterUtility"
    
    nonisolated static let introSpaceId = "IntroSpace"
    nonisolated static let outroSpaceId = "OutroSpace"
    nonisolated static let labSpaceId = "LabSpace"
    nonisolated static let buildingSpaceId = "BuildingSpace"
    nonisolated static let attackSpaceId = "AttackSpace"
}

enum AppPhase: String, CaseIterable, Codable, Sendable, Equatable {
    case loading
    case ready
    case intro
    case lab
    case building
    case playing
    case completed
    case outro
    case error
    
    var needsImmersiveSpace: Bool {
        return self != .loading && self != .error && self != .building && self != .ready
    }
    
    var needsHandTracking: Bool {
        switch self {
        case .intro, .lab, .building, .playing:
            return true
        case .loading, .completed, .outro, .ready, .error:
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
        case .loading, .ready, .error: return ""
        }
    }
    
    var windowId: String {
        switch self {
        case .loading, .ready, .completed: return AppModel.mainWindowId 
        case .intro: return AppModel.introWindowId
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
    let trackingManager = TrackingSessionManager()
    
    var shouldDimSurroundings: Bool = false
    
    /// Current phase of the app
    var currentPhase: AppPhase = .loading
    
    // MARK: - Immersive Space Management
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    
    enum DismissReason {
        case manual    // Our code dismissed it
        case system    // Digital Crown or system dismissed it
    }
    
    var immersiveSpaceState: ImmersiveSpaceState = .closed
    var immersiveSpaceDismissReason: DismissReason?
    var triggerImmersiveSpace = false
    
    var gameState: AttackCancerViewModel
    var isDebugWindowOpen = true
    var isHopeMeterUtilityWindowOpen = false
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

    func toggleLibrary() {
        if isLibraryWindowOpen {
            isLibraryWindowOpen = false
        } else {
            isLibraryWindowOpen = true
        }
    }
    
    // MARK: - Space Management
    @ObservationIgnored private var currentImmersiveSpace: String?
    @ObservationIgnored private(set) var isTransitioning = false
    
    var hasImmersiveSpace: Bool {
        return currentImmersiveSpace != nil
    }
    
    // MARK: Start the Attack Cancer Game
    
    
    var shouldStartGame: Bool {
        gameState.tutorialComplete && gameState.isHopeMeterRunning
    }
    
    func startAttackCancerGame() {
        gameState.tutorialComplete = true
        startHopeMeter()
    }
    
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
        self.gameState = AttackCancerViewModel()
        self.gameState.appModel = self
        self.gameState.handTracking = self.trackingManager.handTrackingManager
    }
    
    // MARK: - Phase Management
    @MainActor
    func transitionToPhase(_ newPhase: AppPhase, adcDataModel: ADCDataModel? = nil) async {
        print("🔄 Phase transition: \(currentPhase) -> \(newPhase)")
        guard !isTransitioning else { return }
        isTransitioning = true
        defer { isTransitioning = false }
        
        // First stop tracking if we're in a phase that uses it
        if currentPhase.needsHandTracking {
            trackingManager.stopTracking()
        }
        
        // Set the new phase
        currentPhase = newPhase
        
        // Then start tracking if the new phase needs it
        if newPhase.needsHandTracking {
            // Add a small delay to ensure ARKit has time to clean up
            try? await Task.sleep(for: .milliseconds(100))
            try? await trackingManager.startTracking(needsHandTracking: newPhase.needsHandTracking)
        }
        
        // Handle ADC setup for playing phase
        if newPhase == .playing, let adcDataModel = adcDataModel {
            if let adcEntity = await assetLoadingManager.instantiateEntity("adc") {
                gameState.setADCTemplate(adcEntity, dataModel: adcDataModel)
            }
        }
        print("✅ Phase transition complete: \(newPhase)")
    }
    
    // Keep all other existing methods...
    
    // Remove ARKit session management code that's moved to TrackingSessionManager:
    // - runARKitSession()
    // - monitorSessionEvents()
    // - arkitSession and provider properties
    
    var isTutorialStarted: Bool = false
    
    // Track instruction window state
    var isInstructionsWindowOpen = false
    
    func startTutorial() {
        isTutorialStarted = true
        
    }
}
