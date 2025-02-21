import SwiftUI
import RealityKit
import RealityKitContent

extension AttackCancerViewModel {
    // MARK: - Pool Management
    
    /// Initialize pool of cancer cells
    @MainActor
    func initializePool(in root: Entity, template: Entity) async -> Int {
        Logger.info("\n=== Initializing Cancer Cell Pool ===")
        
        for i in 0..<maxCancerCells {
            Logger.info("\n=== Pre-creating Cancer Cell \(i) ===")
            
            let cell = template.clone(recursive: true)
            cell.name = "cancer_cell_\(i)"
            
            if let complexCell = cell.findEntity(named: "cancerCell_complex") {
                complexCell.opacity = 0
                
                // Setup all the physical aspects first
                configureCellPosition(complexCell, preferFront: false)
                configureCellPhysics(complexCell)
                configureCellMovement(complexCell)
                setupCellIdentification(complexCell, cellID: i)
                
                // Create parameters on-demand
                let parameters = CancerCellParameters(cellID: i)
                Logger.info("Creating parameters for cell \(i)")
                Logger.info("Required hits: \(parameters.requiredHits)")
                cellParameters.append(parameters)
                Logger.info("Total parameters after append: \(cellParameters.count)")
                
                // Add state component with reference to parameters
                cell.components.set(CancerCellStateComponent(parameters: parameters))
                Logger.info("Added CancerCellStateComponent with parameters")
                
                // Add to root and setup attachment points
                cell.isEnabled = false  // Pool-specific: start disabled
                root.addChild(cell)
                setupAttachmentPoints(for: cell, complexCell: complexCell, cellID: i)

                Logger.info("\n=== Cancer Cell Pool \(i) Hierarchy ===")
                // appModel.assetLoadingManager.inspectEntityHierarchy(cell)
                
                // Pool-specific: add to available cells
                availableCells.append(cell)
                Logger.info("✅ Successfully pre-created cell \(i)")
                Logger.info("📦 Stored in pool: Entity named '\(complexCell.name)' with parent '\(complexCell.parent?.name ?? "none")'")
            }
        }
        
        Logger.info("=== Pool Initialization Complete ===")
        Logger.info("Total cells pre-created: \(availableCells.count)")
        Logger.info("Total parameters created: \(cellParameters.count)")
        return availableCells.count
    }
    
    /// Get next available cell from pool
    @MainActor
    func acquireCell(preferFront: Bool = false) -> Entity? {
        guard let cell = availableCells.popLast() else { return nil }
        
        if let complexCell = cell.findEntity(named: "cancerCell_complex") {
            configureCellPosition(complexCell, preferFront: preferFront)
        }
        
        cell.isEnabled = true
        activeCells.append(cell)
        return cell
    }
    
    /// Reset pool to initial state
    @MainActor
    func resetPool() {
        // Move all active cells back to available
        activeCells.forEach { cell in
            cell.isEnabled = false
            if let complexCell = cell.findEntity(named: "cancerCell_complex") {
                complexCell.opacity = 0
            }
            availableCells.append(cell)
        }
        activeCells.removeAll()
        
        Logger.debug("Pool reset. All cells returned to available state")
    }
} 