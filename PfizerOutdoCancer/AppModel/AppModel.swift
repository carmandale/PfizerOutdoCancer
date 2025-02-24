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
    
    enum PositioningDefaults {
        case intro
        case building
        case playing
        
        var position: SIMD3<Float> {
            switch self {
            case .intro:    return SIMD3<Float>(0.0, -1.5, -1.0)
            case .building: return SIMD3<Float>(0.0, 1.2, -1.0)
            case .playing:  return SIMD3<Float>(0.0, 1.5, -1.0)
            }
        }
    }
    
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
        return self != .loading && self != .error && self != .building 
    }
    
    var needsHandTracking: Bool {
        switch self {
        case .intro, .lab, .building, .playing, .ready:
            return true
        case .loading, .completed, .outro, .error:
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
        case .ready: return AppModel.introSpaceId
        case .loading, .error: return ""
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
    var currentImmersiveSpace: String?
    @ObservationIgnored private(set) var isTransitioning = false
    
    var hasImmersiveSpace: Bool {
        return currentImmersiveSpace != nil
    }
    
    // MARK: Start the Attack Cancer Game
    
    
    var shouldStartGame: Bool {
        gameState.tutorialComplete && gameState.isHopeMeterRunning
    }
    
    func startAttackCancerGame() {
        Logger.debug("🎮 Starting Attack Cancer Game (startAttackCancerGame called)")
        Logger.debug("Starting Hope Meter")
        startHopeMeter()
    }
    
    // MARK: - Hope Meter Management
    @ObservationIgnored private var hopeMeterTimer: Timer?
    
    func startHopeMeter() {
        Logger.debug("🕒 Starting Hope Meter (startHopeMeter called)")
        stopHopeMeter() // Ensure any existing timer is cleaned up
        
        gameState.hopeMeterTimeLeft = gameState.hopeMeterDuration // Reset timer
        gameState.isHopeMeterRunning = true
        
        // Create a task to trigger the ending sequence at 19 seconds
        Task { @MainActor in
            // Wait until 19 seconds remain (hopeMeterDuration - 19 seconds)
            try? await Task.sleep(for: .seconds(gameState.hopeMeterDuration - 19))
            
            // Check if we're still running before playing
            if gameState.isHopeMeterRunning {
                Logger.debug("playingEndingSequence audio")
                await gameState.playEndingSequence()
            }
        }
        
        hopeMeterTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                if self.gameState.hopeMeterTimeLeft > 0 {
                    self.gameState.hopeMeterTimeLeft -= 1
                } else {
                    self.stopHopeMeter()
                    await self.gameState.hopeMeterDidRunOut()
                    // wait a second for the sound and then transition
                    try? await Task.sleep(for: .milliseconds(2000))
                    await self.transitionToPhase(.completed)
                }
            }
        }
    }
    
    func stopHopeMeter() {
        Logger.debug("🛑 Stopping Hope Meter")
        hopeMeterTimer?.invalidate()
        hopeMeterTimer = nil
        gameState.isHopeMeterRunning = false
    }

    // @MainActor // simplified version of accelerateHopeMeterToCompletion
    // func accelerateHopeMeterToCompletion() async {
    //     Logger.debug("🚀 Accelerating hope meter to completion")
    //     Logger.debug("Initial state: hopeMeterTimeLeft=\(gameState.hopeMeterTimeLeft), isHopeMeterRunning=\(gameState.isHopeMeterRunning)")
        
    //     stopHopeMeter() // Ensure clean slate
    //     gameState.hopeMeterTimeLeft = 0
    //     Logger.debug("Accelerated to: hopeMeterTimeLeft=\(gameState.hopeMeterTimeLeft), isHopeMeterRunning=\(gameState.isHopeMeterRunning)")
    // }
    
    @MainActor
    func accelerateHopeMeterToCompletion() async {
        Logger.debug("""
        
        🚀 === ACCELERATING HOPE METER ===
        ├─ Current Phase: \(currentPhase)
        ├─ Initial Time Left: \(gameState.hopeMeterTimeLeft)
        ├─ Is Running: \(gameState.isHopeMeterRunning)
        ├─ Has Played Victory: \(gameState.hasPlayedVictorySequence)
        └─ Has Played Ending: \(gameState.hasPlayedEndingSequence)
        """)
        
        // Stop the normal timer
        hopeMeterTimer?.invalidate()
        hopeMeterTimer = nil
        Logger.debug("Stopped normal timer")
        
        // Create a fast timer to quickly count down
        let totalTime: TimeInterval = 2.0
        let updateInterval: TimeInterval = 0.05
        let totalSteps = Int(totalTime / updateInterval)
        let timePerStep = gameState.hopeMeterTimeLeft / TimeInterval(totalSteps)
        
        for step in 0..<totalSteps {
            gameState.hopeMeterTimeLeft = max(0, gameState.hopeMeterTimeLeft - timePerStep)
            if step % 10 == 0 { // Log every 10th step to avoid spam
                Logger.debug("Time remaining: \(gameState.hopeMeterTimeLeft)")
            }
            try? await Task.sleep(for: .milliseconds(Int(updateInterval * 1000)))
        }
        
        gameState.hopeMeterTimeLeft = 0
        gameState.isHopeMeterRunning = false
        
        Logger.debug("""
        
        ✅ === ACCELERATION COMPLETE ===
        ├─ Final Time Left: \(gameState.hopeMeterTimeLeft)
        ├─ Is Running: \(gameState.isHopeMeterRunning)
        └─ Current Phase: \(currentPhase)
        """)
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
        self.trackingManager.appModel = self  // Set the reference to AppModel
        Logger.debug("AppModel init() - Instance: \(ObjectIdentifier(self))")
    }
    
    // MARK: - Phase Management
    @MainActor
    func transitionToPhase(_ newPhase: AppPhase, adcDataModel: ADCDataModel? = nil) async {
        Logger.info("""
        
        🔄 === PHASE TRANSITION START ===
        ├─ From: \(currentPhase)
        ├─ To: \(newPhase)
        ├─ Current Tracking State: \(trackingManager.worldTrackingProvider.state)
        ├─ Has Hand Tracking: \(currentPhase.needsHandTracking)
        ├─ Will Need Hand Tracking: \(newPhase.needsHandTracking)
        ├─ Immersive Space State: \(immersiveSpaceState)
        ├─ Asset Loading State: \(assetLoadingManager.state)
        └─ Is Transitioning: \(isTransitioning)
        """)
        
        Logger.debug("🔄 Phase transition: \(currentPhase) -> \(newPhase)")
        Logger.debug("🔍 isTransitioning: \(isTransitioning)")
        Logger.debug("🔍 immersiveSpaceState: \(immersiveSpaceState)")
        guard !isTransitioning else {
            Logger.debug("⚠️ Already transitioning, skipping")
            return
        }
        isTransitioning = true
        defer { 
            isTransitioning = false 
            Logger.debug("✅ Phase transition completed: \(newPhase)")
        }

        // 1. Stop tracking if we're in a phase that uses it
        if currentPhase.needsHandTracking {
            Logger.info("🛑 Stopping tracking for phase transition")
            await trackingManager.stopTracking()
            
            do {
                // Wait for tracking to fully stop with verification
                try await trackingManager.waitForCleanup()
                if !trackingManager.verifyProviderState(expectRunning: false) {
                    Logger.error("❌ Tracking cleanup verification failed")
                    // Continue with transition but log the error
                }
            } catch {
                Logger.error("❌ Tracking cleanup failed: \(error)")
                // Continue with transition but log the error
            }
            
            Logger.info("📊 Post-Stop Tracking State: \(trackingManager.worldTrackingProvider.state)")
        }

        // 2. Pre-load assets for the new phase before cleanup
        await preloadAssets(for: newPhase, adcDataModel: adcDataModel)

        // 3. Clean up current phase
        await cleanupCurrentPhase(for: newPhase, adcDataModel: adcDataModel)

        // 4. Set the new phase before starting tracking
        currentPhase = newPhase

        // 5. Start tracking if needed with retry logic
        if newPhase.needsHandTracking {
            await startTrackingWithRetry(for: newPhase)
        }

        // After cleanup
        Logger.info("""
        
        🧹 === Post-Cleanup State ===
        ├─ Asset Manager State: \(assetLoadingManager.state)
        ├─ Immersive Space: \(immersiveSpaceState)
        ├─ Tracking State: \(trackingManager.worldTrackingProvider.state)
        └─ Cached Assets: \(assetLoadingManager.entityTemplates.keys.joined(separator: ", "))
        """)

        // After phase set
        Logger.info("""
        
        📍 === Phase Set Complete ===
        ├─ New Phase: \(newPhase)
        ├─ Asset State: \(assetLoadingManager.state)
        ├─ Space State: \(immersiveSpaceState)
        └─ Tracking Ready: \(newPhase.needsHandTracking)
        """)
    }

    /// Attempts to start tracking with retry logic
    private func startTrackingWithRetry(for phase: AppPhase) async {
        let maxRetries = 3
        var trackingStarted = false
        
        for attempt in 1...maxRetries {
            do {
                // Add a small delay between attempts
                if attempt > 1 {
                    try await Task.sleep(for: .milliseconds(100))
                }
                
                try await trackingManager.startTracking(needsHandTracking: phase.needsHandTracking)
                
                // Verify tracking state
                if trackingManager.verifyProviderState(expectRunning: true) {
                    trackingStarted = true
                    Logger.info("✅ Tracking started successfully on attempt \(attempt)")
                    break
                } else {
                    Logger.error("❌ Provider state verification failed on attempt \(attempt)")
                }
            } catch {
                Logger.error("""
                
                ❌ Tracking start failed (Attempt \(attempt)/\(maxRetries))
                ├─ Error: \(error)
                ├─ Phase: \(phase)
                └─ Provider State: \(trackingManager.worldTrackingProvider.state)
                """)
                
                if attempt == maxRetries {
                    Logger.error("❌ All tracking start attempts failed")
                }
            }
        }
        
        if !trackingStarted {
            Logger.error("❌ Failed to start tracking after \(maxRetries) attempts")
            // Consider transitioning to error state or implementing recovery logic
        }
    }

    private func preloadAssets(for phase: AppPhase, adcDataModel: ADCDataModel?) async {
        if phase == .intro || phase == .playing {
            Logger.debug("\n=== Preparing ADC for intro and playing ===")
            if let adcDataModel = adcDataModel {
                do {
                    // Use cached template and update colors
                    if let cachedTemplate = assetLoadingManager.entityTemplates["adc"] {
                        Logger.debug("🎯 Using cached ADC template...")
                        gameState.setADCTemplate(cachedTemplate, dataModel: adcDataModel)
                        Logger.debug("✅ Updated ADC template colors")
                        
                        // Pass template to lab state if we have built an ADC
                        labState.adcTemplate = gameState.adcTemplate
                        Logger.debug("✅ ADC template passed to lab state")
                    } else {
                        Logger.debug("❌ No cached ADC template found")
                    }

                } catch {
                    Logger.debug("❌ Failed to load playing phase assets: \(error)")
                }
            } else {
                Logger.debug("❌ No ADCDataModel available for playing phase")
            }
        }
        if phase == .playing {
            Logger.debug("\n=== Pre-loading Playing Phase Assets ===")
            Logger.debug("📱 Pre-loading required assets for playing phase...")
            if adcDataModel != nil {
                do {
                    
                    // Ensure tutorial asset is loaded and cached
                    Logger.debug("🎯 Loading tutorial assets...")
                    _ = try await assetLoadingManager.instantiateAsset(
                        withName: "game_start_vo",
                        category: .attackCancerEnvironment
                    )
                    Logger.debug("✅ Tutorial assets cached")

                    // ADDED: Load and cache attack_cancer_environment
                    Logger.debug("🎯 Loading attack_cancer_environment...")
                    _ = try await assetLoadingManager.instantiateAsset(
                        withName: "attack_cancer_environment",
                        category: .attackCancerEnvironment
                    )
                    Logger.debug("✅ attack_cancer_environment cached")
                    try? await Task.sleep(for: .milliseconds(100)) // Small delay
                    Logger.debug("✅✅✅ Playing Phase Assets Ready (with delay) ===\n") // More emphatic message

                } catch {
                    Logger.debug("❌ Failed to load playing phase assets: \(error)")
                }
            } else {
                Logger.debug("❌ No ADCDataModel available for playing phase")
            }
        } else if phase == .outro {
            Logger.debug("\n=== Pre-loading Outro Phase Assets ===")
            Logger.debug("📱 Pre-loading outro environment...")
            do {
                _ = try await assetLoadingManager.instantiateAsset(
                    withName: "outro_environment",
                    category: .outroEnvironment
                )
                Logger.debug("✅ Outro environment cached")
                Logger.debug("=== Outro Phase Assets Ready ===\n")
            } catch {
                Logger.debug("❌ Failed to pre-load outro environment: \(error)")
            }
        } else if phase == .building {
            os_log(.debug, "AppModel: Preloading Building Phase Assets...")
            // Optionally trigger a preloading for building assets if needed (for example, loading "antibody_scene" here)
            do {
                _ = try await assetLoadingManager.instantiateAsset(
                    withName: "antibody_scene",
                    category: .buildADCEnvironment
                )
                // os_log(.debug, "AppModel: Preloaded antibody_scene for Building Phase: %@", String(describing: scene))
            } catch {
                os_log(.error, "AppModel: Failed to preload Building Phase asset 'antibody_scene': %@", error.localizedDescription)
            }
        }
    }


    private func cleanupCurrentPhase(for newPhase: AppPhase, adcDataModel: ADCDataModel?) async {
        switch currentPhase {
        case .intro:
            introState.cleanup()
            await assetLoadingManager.releaseIntroEnvironment()
            labState.cleanup()
            await assetLoadingManager.releaseLabEnvironment()
        case .lab:
            labState.cleanup()
            await assetLoadingManager.releaseLabEnvironment()
        case .building:
            Logger.debug("Cleaning up building phase")
            if let adcDataModel = adcDataModel {
                adcDataModel.cleanup()
            }
            await assetLoadingManager.releaseBuildADCEnvironment()
        case .playing:
            if newPhase != .completed {
                Logger.debug("""
                
                🧹 === CLEANING UP PLAYING PHASE ===
                ├─ Next Phase: \(newPhase)
                ├─ Hope Meter Running: \(gameState.isHopeMeterRunning)
                ├─ Hope Meter Time: \(gameState.hopeMeterTimeLeft)
                └─ Audio States: Victory=\(gameState.hasPlayedVictorySequence), Ending=\(gameState.hasPlayedEndingSequence)
                """)
                
                // Stop any running timers
                stopHopeMeter()
                
                // Reset hope meter state
                gameState.hopeMeterTimeLeft = gameState.hopeMeterDuration
                gameState.isHopeMeterRunning = false
                
                await gameState.cleanup()
                await assetLoadingManager.releaseAttackCancerEnvironment()
                
                Logger.debug("✅ Playing phase cleanup complete")
            } else {
                Logger.debug("Preserving immersive assets for completed phase")
            }
        case .completed:
            if newPhase == .outro {
                await gameState.fadeOutScene()
                try? await Task.sleep(for: .seconds(0.5))
            } else {
                Logger.debug("I am in the completed phase and transitioning to \(newPhase); cleaning up normally.")
                await gameState.cleanup()
                await assetLoadingManager.releaseAttackCancerEnvironment()
            }
        case .outro:
            outroState.cleanup()
            await assetLoadingManager.releaseOutroEnvironment()
        case .ready, .loading, .error:
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
