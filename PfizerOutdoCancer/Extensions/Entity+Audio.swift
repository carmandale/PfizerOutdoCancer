import RealityKit

extension Entity {
    
    /// Enables a large room reverb effect on the entity.
    func enableLargeRoomReverb() {
        // Create the ReverbComponent with the large room preset.
        let largeRoomReverb = ReverbComponent(reverb: .preset(.largeRoom))
        // Attach the reverb component to the entity.
        self.components.set(largeRoomReverb)
    }
    
    /// Disables any active reverb effect on the entity.
    func disableReverb() {
        // Remove the ReverbComponent from the entity.
        self.components.remove(ReverbComponent.self)
    }
}
