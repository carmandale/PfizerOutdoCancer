import SwiftUI
import RealityKit
import RealityKitContent
import Combine

@Observable
@MainActor
final class AttackCancerViewModel {
    // MARK: - State Tracking
    var isRootSetupComplete: Bool = false
    var isEnvironmentSetupComplete: Bool = false
    var shouldUpdateHeadPosition: Bool = false
    var isHeadTrackingRootReady: Bool = false
    var isPositioningComplete: Bool = false
    var isTutorialAlertVisible: Bool = false
    var isPinchAnimationVisible: Bool = false
    
    // Track when we're fully ready for interactions
    var isReadyForInteraction: Bool {
        isRootSetupComplete && 
        isEnvironmentSetupComplete && 
        isHeadTrackingRootReady
    }
    
    // MARK: - Collision Filters
    static var adcFilter: CollisionFilter {
        let adcMask = CollisionGroup.all.subtracting(adcGroup)
        return CollisionFilter(group: adcGroup, mask: adcMask)
    }
    
    static var cancerCellFilter: CollisionFilter {
        let cellMask = CollisionGroup.all.subtracting(cancerCellGroup)
        return CollisionFilter(group: cancerCellGroup, mask: cellMask)
    }
    
    static var microscopeFilter: CollisionFilter {
        let microscopeMask = CollisionGroup.all
        return CollisionFilter(group: microscopeGroup, mask: microscopeMask)
    }

    // MARK: - Collision Groups
    static let adcGroup = CollisionGroup(rawValue: 1 << 0)
    static let cancerCellGroup = CollisionGroup(rawValue: 1 << 1)
    static let microscopeGroup = CollisionGroup(rawValue: 1 << 2)
    
    // MARK: - Collision Properties
    var debounce: [UnorderedPair<Entity>: TimeInterval] = [:]
    let debounceThreshold: TimeInterval = 0.1
    
    // MARK: - Properties
    var storedAttachments: RealityViewAttachments?
    var rootEntity: Entity?
    var scene: RealityKit.Scene?
    var handTrackedEntity: Entity?
    var isSetupComplete = false
    var environmentLoaded = false
    var tutorialCancerCell: Entity?
    var testFireCell: Entity?
    var tutorialComplete = false
    var isTestFireActive = false
    var testFireComplete = false
    var readyToStartGame = false

    // MARK: - Audio Debug Properties
    var audioDebugCone: ModelEntity?
    var isAudioDebugVisible: Bool = true

    var shouldPlayStartButtonVO: Bool {
        readyToStartGame && tutorialComplete
    }

    // MARK: - Properties for Audio
    var endGameAudioSource: Entity?
    var endGameAudioResource: AudioFileResource?
    var endGameAudioController: AudioPlaybackController?
    var loadedAudioResources: [String: AudioFileResource] = [:]
    
    // MARK: - Sequence-specific Audio Properties
    var endingSequenceAudioSource: Entity?
    var victorySequenceAudioSource: Entity?
    var greatJobAudioSource: Entity?
    var endingSequenceController: AudioPlaybackController?
    var victorySequenceController: AudioPlaybackController?
    var greatJobController: AudioPlaybackController?
    // Add flags to track if sequences have played
    var hasPlayedEndingSequence = false
    var hasPlayedVictorySequence = false
    var hasPlayedGreatJob = false
    
    // MARK: - Transition Properties
    var isTransitioningOut = false
    var transitionOpacity: Float = 1.0
    
    // Store subscription to prevent deallocation
    internal var subscription: Cancellable?
    
    // Dependencies
    var appModel: AppModel!
    var handTracking: HandTrackingManager!
    
    // MARK: - Game Stats
    var hitProbability: Double = 0.3
    var maxCancerCells: Int = 20
    var cellsDestroyed: Int = 0
    var totalADCsDeployed: Int = 0
    var totalTaps: Int = 0
    var totalHits: Int = 0
    
    // MARK: - Hope Meter
    let hopeMeterDuration: TimeInterval = 30
    var hopeMeterTimeLeft: TimeInterval
    var isHopeMeterRunning = false
    
    var isGameActive: Bool {
        // Only consider the game active if both tutorial is complete AND hope meter is running
        tutorialComplete && testFireComplete && isHopeMeterRunning
    }
    
    // MARK: CELL PROPERTIES
    // ADC Properties
    var adcTemplate: Entity?
    var hasFirstADCBeenFired = false
    
    // Cell State Properties
    var cellParameters: [CancerCellParameters] = []
    
    // Pool Properties
    var availableCells: [Entity] = []
    var activeCells: [Entity] = []
    
    // Add after other private properties
    let tutorialADCDelays: [TimeInterval] = [
        2.0,  // First ADC at 2s
        1.9,  // Second ADC at 3.9s
        1.9,  // Third ADC at 5.8s
        1.9,  // Fourth ADC at 7.7s
        1.9,  // Fifth ADC at 9.6s
        1.9,  // Sixth ADC at 11.5s
        1.9,  // Seventh ADC at 13.4s
        1.9,  // Eighth ADC at 15.3s
        1.9,  // Ninth ADC at 17.2s
        1.8   // Tenth ADC at 19s
    ]
    
    // Root entity for the instructions view
    var instructionsRootEntity: Entity?
    
    // NEW: Store a reference to the CancerCellSystem.
    var cancerCellSystem: CancerCellSystem?
    
    // MARK: - Initialization
    init() {
        // Initialize handTrackedEntity
        self.handTrackedEntity = {
            let handAnchor = AnchorEntity(.hand(.left, location: .aboveHand))
            return handAnchor
        }()
        
        // Initialize hopeMeterTimeLeft
        self.hopeMeterTimeLeft = hopeMeterDuration
    }
    
    // MARK: - Cleanup and Reset Functions
    
    /// Tracks the current state of cleanup operations
    enum CleanupState {
        case none        // No cleanup in progress
        case gameOnly    // tearDownGame() in progress/complete
        case complete    // full cleanup() in progress/complete
    }
    
    /// Current cleanup state
    var cleanupState: CleanupState = .none
    
    /// Flag to prevent concurrent cleanup operations
    private var isCleaningUp = false

    /// Tears down the current game session's content while preserving the core system.
    /// Use this for cleaning up game-specific content without full system shutdown.
    ///
    /// Responsibilities:
    /// - Removes game entities (cells, ADCs)
    /// - Cleans up VO content
    /// - Resets positioning components
    /// - Cancels game-specific subscriptions
    /// - Does NOT clear core system references
    /// - Does NOT remove root entities
    /// - Does NOT affect app model connections
    ///
    /// Call this when:
    /// - Transitioning between game phases
    /// - Ending a game session
    /// - Preparing for a new game session
    func tearDownGame() async {
        // Prevent duplicate teardown
        guard cleanupState == .none else {
            Logger.debug("⚠️ Tear down already in progress or completed: \(cleanupState)")
            return
        }
        
        cleanupState = .gameOnly
        print("\n=== Tearing Down Game [Detailed] ===")
        print("📊 Initial State:")
        print("  - Hope Meter Running: \(isHopeMeterRunning)")
        print("  - Tutorial Started: \(appModel.isTutorialStarted)")
        print("  - Current Phase: \(appModel.currentPhase)")
        print("  - Test Fire Active: \(isTestFireActive)")
        
        // Stop systems first
        appModel.stopHopeMeter()
        subscription?.cancel()
        subscription = nil
        
        // Stop all audio playback
        Logger.audio("Stopping all audio playback...")
        
        // Stop and clear end game audio
        endGameAudioController?.stop()
        endGameAudioController = nil
        if let audioSource = endGameAudioSource {
            audioSource.removeFromParent()
            Logger.audio("Removed end game audio source")
        }
        
        // Stop and clear ending sequence audio
        endingSequenceController?.stop()
        endingSequenceController = nil
        if let audioSource = endingSequenceAudioSource {
            audioSource.removeFromParent()
            Logger.audio("Removed ending sequence audio source")
        }
        
        // Stop and clear victory sequence audio
        victorySequenceController?.stop()
        victorySequenceController = nil
        if let audioSource = victorySequenceAudioSource {
            audioSource.removeFromParent()
            Logger.audio("Removed victory sequence audio source")
        }
        
        // Stop and clear great job audio
        greatJobController?.stop()
        greatJobController = nil
        if let audioSource = greatJobAudioSource {
            audioSource.removeFromParent()
            Logger.audio("Removed great job audio source")
        }
        
        // Reset sequence flags
        hasPlayedEndingSequence = false
        hasPlayedVictorySequence = false
        hasPlayedGreatJob = false
        Logger.audio("✅ Reset all sequence flags")
        
        // Clear gameplay state
        cellParameters.removeAll()
        cellsDestroyed = 0
        totalADCsDeployed = 0
        totalTaps = 0
        totalHits = 0
        
        // Clear debounce dictionary
        debounce.removeAll()

        // Remove gameplay entities
        if let root = rootEntity {
            print("\n🔍 Examining root entity: \(root.name)")
            
            // Remove cancer cells
            var removedCells = 0
            for i in 0..<maxCancerCells {
                if let cell = root.findEntity(named: "cancer_cell_\(i)") {
                    cell.removeFromParent()
                    removedCells += 1
                }
            }
            // Remove test fire cell if it exists
            if let testFireCell = root.findEntity(named: "cancer_cell_555") {
                testFireCell.removeFromParent()
                removedCells += 1
            }
            print("🗑️ Removed cancer cells: \(removedCells)")
            
            // Remove ADCs
            if let scene = root.scene {
                let adcQuery = EntityQuery(where: .has(ADCComponent.self))
                scene.performQuery(adcQuery).forEach { entity in
                    entity.removeFromParent()
                }
            }
            
            // Remove any VO entities from headTrackingRoot
            if let VO_parent = root.findEntity(named: "headTrackingRoot") {
                Logger.info("\n🎯 Cleaning up head tracking root")
                // Remove all child entities
                VO_parent.children.forEach { child in
                    child.removeFromParent()
                }
                
                // Reset positioning component to clean state
                if var positioningComponent = VO_parent.components[PositioningComponent.self] {
                    Logger.info("├─ Resetting PositioningComponent state")
                    positioningComponent.needsPositioning = false
                    positioningComponent.shouldAnimate = false
                    positioningComponent.animationDuration = 0.0
                    VO_parent.components[PositioningComponent.self] = positioningComponent
                }
                
                Logger.info("└─ Head tracking cleanup complete")
            }
        }
        
        print("✅ Game tear down complete\n")
    }

    /// Performs complete system cleanup and shutdown.
    /// Use this for full system teardown when leaving the game entirely.
    ///
    /// Responsibilities:
    /// - Performs game teardown first
    /// - Removes all entities including root
    /// - Clears all system references
    /// - Resets all flags to initial state
    /// - Prepares system for complete shutdown
    ///
    /// Call this when:
    /// - Exiting the game completely
    /// - Transitioning to a different app section
    /// - Requiring complete system reset
    func cleanup() async {
        guard !isCleaningUp else {
            Logger.debug("⚠️ Cleanup already in progress")
            return
        }
        guard cleanupState != .complete else {
            print("⚠️ Cleanup already completed")
            return
        }
        
        isCleaningUp = true
        print("\n=== Starting AttackCancerViewModel Cleanup ===")
        print("Current Phase: \(appModel.currentPhase)")
        print("Is Transitioning: \(appModel.isTransitioning)")
        
        // First tear down the game if not already done
        if cleanupState != .gameOnly {
            await tearDownGame()
        }
        
        // Clear entity references
        if let root = rootEntity {
            print("🗑️ Removing root entity")
            root.removeFromParent()
        }
        
        // Clear all references
        rootEntity = nil
        scene = nil
        tutorialCancerCell = nil
        instructionsRootEntity = nil
        
        // Only clear ADC template if we're not preserving a custom one
        if !appModel.hasBuiltADC {
            adcTemplate = nil
            Logger.debug("🔄 Clearing temporary ADC template")
        } else {
            Logger.debug("✅ Preserving custom ADC template")
        }
        
        // Clear audio system references with detailed logging
        Logger.audio("\n=== Clearing All Audio Systems ===")
        
        // Clear end game audio
        endGameAudioSource = nil
        endGameAudioResource = nil
        endGameAudioController = nil
        Logger.audio("✅ Cleared end game audio system")
        
        // Clear sequence-specific audio
        endingSequenceAudioSource = nil
        endingSequenceController = nil
        Logger.audio("✅ Cleared ending sequence audio system")
        
        victorySequenceAudioSource = nil
        victorySequenceController = nil
        Logger.audio("✅ Cleared victory sequence audio system")
        
        greatJobAudioSource = nil
        greatJobController = nil
        Logger.audio("✅ Cleared great job audio system")
        
        // Clear audio resources
        loadedAudioResources.removeAll()
        Logger.audio("✅ Cleared all loaded audio resources")
        
        // Clear audio flags
        hasPlayedEndingSequence = false
        hasPlayedVictorySequence = false
        hasPlayedGreatJob = false
        Logger.audio("✅ Reset all audio playback flags")
        
        // Clear debug visuals
        audioDebugCone = nil
        Logger.audio("✅ Cleared audio debug visuals")
        Logger.audio("=== Audio System Cleanup Complete ===\n")
        
        // Reset flags
        isSetupComplete = false
        hasFirstADCBeenFired = false
        environmentLoaded = false
        isPositioningComplete = false
        
        cleanupState = .complete
        isCleaningUp = false
        print("✅ Completed AttackCancerViewModel cleanup\n")
    }

    func findCancerCell(withID id: Int) -> Entity? {
        // First check if ID is valid
        guard id >= 0 && id < cellParameters.count else { return nil }
        
        guard let root = rootEntity else { return nil }
        
        // Find the cell entity
        if let cell = root.findEntity(named: "cancer_cell_\(id)") {
            // Validate it has correct state component
            guard let stateComponent = cell.components[CancerCellStateComponent.self],
                  stateComponent.parameters.cellID == id else {
                print("⚠️ Found cell \(id) but state component mismatch")
                return nil
            }
            return cell
        }
        
        print("⚠️ Could not find cancer cell with ID: \(id)")
        return nil
    }

    // MARK: FADE OUT SCENE
    /// Fades out the entire scene gracefully
    /// - Returns: Void
    @MainActor
    func fadeOutScene() async {
        Logger.info("🎬 Starting scene fade out")
        
        guard let root = rootEntity else {
            Logger.debug("⚠️ No root entity found for fade out")
            return
        }
        
        await root.fadeOpacity(
            to: 0.0,
            duration: 2.0,
            timing: .easeInOut,
            waitForCompletion: true
        )
        
        Logger.info("✨ Scene fade out complete")
    }
}
