import SwiftUI
import RealityKit
import RealityKitContent
import Combine

@Observable
@MainActor
final class AttackCancerViewModel {
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
    var tutorialComplete = false
    var isTestFireActive = false
    
    // Store subscription to prevent deallocation
    internal var subscription: Cancellable?
    
    // Dependencies
    var appModel: AppModel!
    var handTracking: HandTrackingManager!
//    var dataModel: ADCDataModel!
    
    // MARK: - Game Stats
    var maxCancerCells: Int = 25
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
        tutorialComplete && isHopeMeterRunning
    }
    
    // MARK: - ADC Properties
    var adcTemplate: Entity?
    var hasFirstADCBeenFired = false
    
    // MARK: - Cell State Properties
    var cellParameters: [CancerCellParameters] = []
    
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

    // MARK: - Cleanup
    enum CleanupState {
        case none
        case gameOnly    // For tearDownGame
        case complete    // For full cleanup
    }

    var cleanupState: CleanupState = .none
    private var isCleaningUp = false

    func tearDownGame() async {
        // Prevent duplicate teardown
        guard cleanupState == .none else {
            print("⚠️ Tear down already in progress or completed: \(cleanupState)")
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
        
        // Clear gameplay state
        cellParameters.removeAll()
        
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
                VO_parent.children.forEach { child in
                    child.removeFromParent()
                }
            }
        }
        
        await resetGameState()
        print("✅ Game tear down complete\n")
    }

    func cleanup() async {
        guard !isCleaningUp else {
            print("⚠️ Cleanup already in progress")
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
        adcTemplate = nil
        
        // Reset flags
        isSetupComplete = false
        hasFirstADCBeenFired = false
        environmentLoaded = false
        
        cleanupState = .complete
        isCleaningUp = false
        print("✅ Completed AttackCancerViewModel cleanup\n")
    }

    // NEW: Reset function to be called at the start of a new game session.
    func resetCleanupForNewSession() {
        // Reset cleanup flags and other related state if needed.
        cleanupState = .none
        isCleaningUp = false
        // Optionally, reinitialize other game state if necessary.
        // For example, you might want to clear cell parameters and reset counters—
        // however, ensure that this reset does not conflict with the
        // app's intended state management.
        print("🔄 AttackCancerViewModel: Cleanup state has been reset for new session.")
    }

    private func resetGameState() async {
        print("\n🔄 Resetting game stats:")
        print("  - Cells Destroyed: \(cellsDestroyed) → 0")
        print("  - Total ADCs: \(totalADCsDeployed) → 0")
        print("  - Total Taps: \(totalTaps) → 0")
        print("  - Total Hits: \(totalHits) → 0")
        
        cellsDestroyed = 0
        totalADCsDeployed = 0
        totalTaps = 0
        totalHits = 0
        hopeMeterTimeLeft = hopeMeterDuration
        isHopeMeterRunning = false
        hasFirstADCBeenFired = false

        // Reset the tutorial and test fire states for a new game session
        appModel.isTutorialStarted = false
        tutorialComplete = false
        appModel.gameState.isTestFireActive = false
        isTestFireActive = false
        print("🔄 Reset tutorial state: isTutorialStarted: \(appModel.isTutorialStarted), tutorialComplete: \(tutorialComplete), isTestFireActive: \(isTestFireActive)")
    }

    var progressiveAttack: ImmersionStyle = .progressive(
        0.1...0.8,
        initialAmount: 0.3
    )

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

    func validateCellAlignment() {
        print("\n=== Validating Cell Alignment ===")
        for (index, parameters) in cellParameters.enumerated() {
            // Validate cellID matches index
            assert(parameters.cellID == index, "Cell parameter ID mismatch: expected \(index), got \(String(describing: parameters.cellID))")
            
            // Validate entity exists and has matching state
            guard let cell = findCancerCell(withID: index),
                  let stateComponent = cell.components[CancerCellStateComponent.self] else {
                assertionFailure("Missing cell or state component for index \(index)")
                continue
            }
            
            // Validate state component references same parameters
            assert(stateComponent.parameters.cellID == parameters.cellID, 
                   "State component parameter mismatch for cell \(index)")
            
            print("✅ Cell \(index) alignment validated")
        }
        print("=== Alignment Validation Complete ===\n")
    }
}
