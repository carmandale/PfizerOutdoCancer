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
import os

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
    
    // MARK: - Global UI Settings
    enum UIConstants {
        // Button Dimensions
        static let buttonCornerRadius: CGFloat = 16
        static let buttonPaddingHorizontal: CGFloat = 24
        static let buttonPaddingVertical: CGFloat = 16
        static let buttonExpandScale: CGFloat = 1.1
        static let buttonPressScale: CGFloat = 0.85
        
        // Animation Durations
        static let buttonHoverDuration: CGFloat = 0.2
        static let buttonPressDuration: CGFloat = 0.3
    }
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
        return self != .loading && self != .error && self != .ready && self != .building 
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
    
    var instructionsWindowId: String? {
        switch self {
        case .playing: return AppModel.mainWindowId // Use main window for instructions
        default: return nil
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
    var readyToStartLab: Bool = false

    // MARK: - Immersion Style
    var introStyle: ImmersionStyle = .mixed
    var outroStyle: ImmersionStyle = .mixed
    var labStyle: ImmersionStyle = .full
    var buildingStyle: ImmersionStyle = .mixed
    var attackStyle: ImmersionStyle = .progressive(
        0.1...1.0,
        initialAmount: 0.85
    )

    // MARK: - Asset Management
    let assetLoadingManager = AssetLoadingManager.shared
    var loadingProgress: Float {
        switch assetLoadingManager.loadingState {
        case .notStarted:
            return 0
        case .loading(let progress):
            return progress
        case .completed:
            return 1
        case .error:
            return 0 // Or handle errors differently
        }
    }
    var displayedProgress: Float = 0.0 // Displayed progress for animation
    
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
        print("🎮 Starting Attack Cancer Game (startAttackCancerGame called)")
        gameState.tutorialComplete = true
        print("✅ Set tutorial complete to true")
        startHopeMeter()
    }
    
    // MARK: - Hope Meter Management
    @ObservationIgnored private var hopeMeterTimer: Timer?
    
    func startHopeMeter() {
        print("🕒 Starting Hope Meter (startHopeMeter called)")
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
        
        // Animate the hope meter to completion using SwiftUI's withAnimation over 2 seconds.
        // This assumes that the UI is bound to gameState.hopeMeterTimeLeft.
        await MainActor.run {
            withAnimation(.easeInOut(duration: 2.0)) {
                gameState.hopeMeterTimeLeft = 0
            }
        }
        
        // Wait for 2 seconds after the animation completes.
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Mark the hope meter as finished.
        await MainActor.run {
            gameState.isHopeMeterRunning = false
        }
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
        print("AppModel init() - Instance: \(ObjectIdentifier(self))")
    }
    
    // MARK: - Phase Management
    @MainActor
    func transitionToPhase(_ newPhase: AppPhase, adcDataModel: ADCDataModel? = nil) async {
        print("🔄 Phase transition: \(currentPhase) -> \(newPhase)")
        print("🔍 isTransitioning: \(isTransitioning)")
        print("🔍 immersiveSpaceState: \(immersiveSpaceState)")
        guard !isTransitioning else {
            print("⚠️ Already transitioning, skipping")
            return
        }
        isTransitioning = true
        defer {
            isTransitioning = false
            print("✅ Phase transition completed: \(newPhase)")
        }

        // 1. Stop tracking if we're in a phase that uses it
        if currentPhase.needsHandTracking {
            trackingManager.stopTracking()
        }

        // 2. Pre-load assets for the *new* phase *before* any cleanup
        await preloadAssets(for: newPhase, adcDataModel: adcDataModel)

        if newPhase == .playing {
            // Before starting the playing session, reinitialize game state.
            gameState.resetCleanupForNewSession()
        }

        // 3. Clean up the *current* phase (guarantee completion with await)
        await cleanupCurrentPhase(for: newPhase)

        // 4. *Now* set the new phase
        currentPhase = newPhase

        // 5. Start tracking if the new phase needs it
        if newPhase.needsHandTracking {
            // Add a small delay to ensure ARKit has time to clean up
            try? await Task.sleep(for: .milliseconds(100))
            try? await trackingManager.startTracking(needsHandTracking: newPhase.needsHandTracking)
        }
    }

    private func preloadAssets(for phase: AppPhase, adcDataModel: ADCDataModel?) async {
        if phase == .playing {
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

                    // ADDED: Load and cache attack_cancer_environment
                    print("🎯 Loading attack_cancer_environment...")
                    _ = try await assetLoadingManager.instantiateAsset(
                        withName: "attack_cancer_environment",
                        category: .attackCancerEnvironment
                    )
                    print("✅ attack_cancer_environment cached")
                    try? await Task.sleep(for: .milliseconds(100)) // Small delay
                    print("✅✅✅ Playing Phase Assets Ready (with delay) ===\n") // More emphatic message

                } catch {
                    print("❌ Failed to load playing phase assets: \(error)")
                }
            } else {
                print("❌ No ADCDataModel available for playing phase")
            }
        } else if phase == .outro {
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
        } else if phase == .building {
            os_log(.debug, "AppModel: Preloading Building Phase Assets...")
            // Optionally trigger a preloading for building assets if needed (for example, loading "antibody_scene" here)
            do {
                let scene = try await assetLoadingManager.instantiateAsset(
                    withName: "antibody_scene",
                    category: .buildADCEnvironment
                )
                os_log(.debug, "AppModel: Preloaded antibody_scene for Building Phase: %@", String(describing: scene))
            } catch {
                os_log(.error, "AppModel: Failed to preload Building Phase asset 'antibody_scene': %@", error.localizedDescription)
            }
        }
    }


    private func cleanupCurrentPhase(for newPhase: AppPhase) async {
        switch currentPhase {
        case .intro:
            // now that intro and lab are combined, we need to cleanup both
            introState.cleanup()
            await assetLoadingManager.releaseIntroEnvironment()
            labState.cleanup()
            await assetLoadingManager.releaseLabEnvironment()
        case .lab:
            labState.cleanup()
            await assetLoadingManager.releaseLabEnvironment()
        case .playing:
            if newPhase != .completed {
                print("I am in the playing phase and I am not transitioning to completed so I am cleaning up")
                await gameState.cleanup()
                await assetLoadingManager.releaseAttackCancerEnvironment()
            } else {
                print("I am in the playing phase and transitioning to completed, so preserving immersive assets")
            }
        case .completed:
            if newPhase != .outro {
                print("I am in the completed phase and transitioning to \(newPhase); cleaning up normally.")
                await gameState.cleanup()
                await assetLoadingManager.releaseAttackCancerEnvironment()
            } else {
                print("Transitioning from completed to outro; preserving immersive assets for AttackCancerView.")
                // Do not call cleanup so that the completed phase's assets remain for the outro.
            }
        case .outro:
            outroState.cleanup()
            await assetLoadingManager.releaseOutroEnvironment()
        case .ready, .loading, .building, .error:
            break // No cleanup needed.
        }
    }
    
    var isTutorialStarted: Bool = false
    
    // Track instruction window state
    var isInstructionsWindowOpen = false
    
    func startTutorial() {
        isTutorialStarted = true
        
    }
}
