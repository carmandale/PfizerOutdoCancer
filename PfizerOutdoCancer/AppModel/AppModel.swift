//
//  AppModel.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman
//

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
    nonisolated static let navWindowId = "DebugNavigation"
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
    var hasBuiltADC: Bool = false
    
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
    var introState: IntroViewModel
    var labState: LabViewModel
    var outroState: OutroViewModel
    var isNavWindowOpen = false
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
        // Single source of truth for library state
        labState.isLibraryOpen.toggle()
    }
    
    func updateLibraryWindowState(isOpen: Bool) {
        isLibraryWindowOpen = isOpen
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
    
    @MainActor
    func accelerateHopeMeterToCompletion() async {
        print("🚀 Accelerating hope meter to completion")
        
        // Stop the normal timer
        hopeMeterTimer?.invalidate()
        hopeMeterTimer = nil
        
        // Calculate how many seconds are left
        let remainingTime = gameState.hopeMeterTimeLeft
        
        // Create a high-frequency timer for smooth animation
        // We'll update 60 times during the 1-second animation
        let updateInterval = 1.0 / 60.0
        let decrementPerUpdate = remainingTime / 60.0
        
        // Animate the timer down over 1 second
        for _ in 0..<60 {
            gameState.hopeMeterTimeLeft -= decrementPerUpdate
            try? await Task.sleep(for: .seconds(updateInterval))
        }
        
        // Ensure we hit exactly zero
        gameState.hopeMeterTimeLeft = 0
        
        // Complete the game
        gameState.isHopeMeterRunning = false
        await transitionToPhase(.completed)
    }
    
    deinit {
        // Since we're on MainActor, we can directly invalidate the timer
        hopeMeterTimer?.invalidate()
        hopeMeterTimer = nil
    }
    
    // MARK: - Initialization
    init() {
        self.gameState = AttackCancerViewModel()
        self.introState = IntroViewModel()
        self.labState = LabViewModel()
        self.outroState = OutroViewModel()
        
        // Set up dependencies
        self.gameState.appModel = self
        self.introState.appModel = self
        self.labState.appModel = self
        self.outroState.appModel = self
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
        
        // Pre-load required assets for playing phase before state change
        if newPhase == .playing {
            print("\n=== Pre-loading Playing Phase Assets ===")
            print("📱 Pre-loading required assets for playing phase...")
            if let adcDataModel = adcDataModel {
                do {
                    // Load and configure ADC template
                    print("🎯 Loading ADC template...")
                    let adcEntity = try await assetLoadingManager.instantiateAsset(
                        withName: "adc",
                        category: .adc
                    )
                    print("✅ ADC entity loaded, applying colors...")
                    gameState.setADCTemplate(adcEntity, dataModel: adcDataModel)
                    print("✅ ADC template configured with colors")
                    
                    // Ensure tutorial asset is loaded and cached
                    print("🎯 Loading tutorial assets...")
                    _ = try await assetLoadingManager.instantiateAsset(
                        withName: "game_start_vo",
                        category: .attackCancerEnvironment
                    )
                    print("✅ Tutorial assets cached")
                    print("=== Playing Phase Assets Ready ===\n")
                } catch {
                    print("❌ Failed to load playing phase assets: \(error)")
                }
            } else {
                print("❌ No ADCDataModel available for playing phase")
            }
        }
        
        // Pre-load outro environment before transitioning to outro phase
        if newPhase == .outro {
            print("\n=== Pre-loading Outro Phase Assets ===")
            print("📱 Pre-loading outro environment...")
            do {
                _ = try await assetLoadingManager.instantiateAsset(
                    withName: "outro_environment",
                    category: .outroEnvironment
                )
                print("✅ Outro environment cached")
                print("=== Outro Phase Assets Ready ===\n")
            } catch {
                print("❌ Failed to pre-load outro environment: \(error)")
            }
        }
        
        // Clean up current phase's view model and assets
        do {
            switch currentPhase {
            case .intro:
                if newPhase != .intro {
                    // First cleanup the view model (clears all entity references)
                    introState.cleanup()
                    // Then release assets from the manager
                    await assetLoadingManager.releaseIntroEnvironment()
                }
            case .lab:
                if newPhase != .lab {
                    // First cleanup the view model (clears all entity references)
                    labState.cleanup()
                    // Then release assets from the manager
                    await assetLoadingManager.releaseLabEnvironment()
                }
            case .playing, .completed:  // Handle both since they share the same space
                if newPhase != .playing && newPhase != .completed {
                    // First cleanup the game state
                    gameState.cleanup()
                    // Then release assets
                    await assetLoadingManager.releaseAttackCancerEnvironment()
                }
            case .outro:
                if newPhase != .outro {
                    // First cleanup the view model (clears all entity references)
                    outroState.cleanup()
                    // Then release assets from the manager
                    await assetLoadingManager.releaseOutroEnvironment()
                }
            case .ready:
                break
            default:
                break
            }
        }
        
        // Set the new phase
        currentPhase = newPhase
        
        // Then start tracking if the new phase needs it
        if newPhase.needsHandTracking {
            // Add a small delay to ensure ARKit has time to clean up
            try? await Task.sleep(for: .milliseconds(100))
            try? await trackingManager.startTracking(needsHandTracking: newPhase.needsHandTracking)
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
