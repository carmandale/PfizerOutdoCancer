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
    var rootEntity: Entity?
    var scene: RealityKit.Scene?
    var handTrackedEntity: Entity?
    
    // Store subscription to prevent deallocation
    internal var subscription: Cancellable?
    
    // Dependencies
    var appModel: AppModel!
    var handTracking: HandTrackingViewModel!
    
    // MARK: - Game Stats
    var maxCancerCells: Int = 3
    var cellsDestroyed: Int = 0
    var totalADCsDeployed: Int = 0
    var totalTaps: Int = 0
    var totalHits: Int = 0
    
    // MARK: - Hope Meter
    let hopeMeterDuration: TimeInterval = 10
    var hopeMeterTimeLeft: TimeInterval
    var isHopeMeterRunning = false
    
    // MARK: - ADC Properties
    var adcTemplate: Entity?
    var hasFirstADCBeenFired = false
    
    // MARK: - Cell State Properties
    var cellParameters: [CancerCellParameters] = []
    
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
}
