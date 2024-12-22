import RealityKit
import Foundation
import RealityKitContent

@MainActor
extension ADCMovementSystem {
    static func resetADC(entity: Entity, component: inout ADCComponent) {
        print("\n=== Resetting ADC ===")
        print("Previous State: \(component.state)")
        print("Previous Target Cell ID: \(String(describing: component.targetCellID))")
        
        // Reset ADC state
        component.state = .idle
        component.targetEntityID = nil
        component.targetCellID = nil
        component.startWorldPosition = nil
        component.movementProgress = 0
        
        // Stop any ongoing animations/audio
        entity.stopAllAnimations()
        entity.stopAllAudio()
        
        print("✅ ADC Reset Complete")
        print("New State: \(component.state)")
    }
}
