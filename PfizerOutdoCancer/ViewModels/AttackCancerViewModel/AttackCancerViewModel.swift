import SwiftUI
import RealityKit
import RealityKitContent
import Combine

struct CellState {
    var hits: Int = 0
    var requiredHits: Int = 0
    var isDestroyed: Bool = false
}

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

    var tutorialComplete: Bool = false
    
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
    var tutorialCancerCell: Entity?
    var cellStates: [CellState] = []
    
    // Store subscription to prevent deallocation
    internal var subscription: Cancellable?
    
    // Dependencies
    var appModel: AppModel!
    var handTracking: HandTrackingManager!
//    var dataModel: ADCDataModel!
    
    // MARK: - Game Stats
    var maxCancerCells: Int = 20
    var cellsDestroyed: Int = 0
    var totalADCsDeployed: Int = 0
    var totalTaps: Int = 0
    var totalHits: Int = 0
    
    // MARK: - Hope Meter
    let hopeMeterDuration: TimeInterval = 30
    var hopeMeterTimeLeft: TimeInterval
    var isHopeMeterRunning = false
    
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

    func tearDownGame() {
        print("\n=== Tearing Down Game ===")
        
        // Stop any running timers/systems
        appModel.stopHopeMeter()
        appModel.isTutorialStarted = false
        
        // // Stop hand tracking session
        // Task {
        //     await handTracking.stopSession()
        // }
        
        // Clear collision subscriptions
        subscription?.cancel()
        subscription = nil
        
        // Clear all cell parameters
        cellParameters.removeAll()
        
        // Remove only gameplay entities from root
        if let root = rootEntity {
            // Remove all cancer cells
            for i in 0..<maxCancerCells {
                if let cell = root.findEntity(named: "cancer_cell_\(i)") {
                    cell.removeFromParent()
                }
            }
            
            // Remove any remaining ADCs using scene query
            if let scene = root.scene {
                let adcQuery = EntityQuery(where: .has(ADCComponent.self))
                scene.performQuery(adcQuery).forEach { entity in
                    entity.removeFromParent()
                }
            }
        }
        
        // Reset game stats
        cellsDestroyed = 0
        totalADCsDeployed = 0
        totalTaps = 0
        totalHits = 0
        
        // Reset flags
        hasFirstADCBeenFired = false
        
        print("✅ Game tear down complete")
    }
}
