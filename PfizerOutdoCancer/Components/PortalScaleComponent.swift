import RealityKit
import Foundation

extension Entity {
    func animateScale(from startScale: Float = 0, to endScale: Float = 1, duration: TimeInterval = 5.0) {
        var time: TimeInterval = 0
        
        components[ClosureComponent.self] = ClosureComponent { deltaTime in
            time += deltaTime
            let progress = min(time / duration, 1.0)
            
            // Interpolate scale
            var transform = self.transform
            transform.scale.x = simd_mix(startScale, endScale, Float(progress))
            self.transform = transform
            
            // Remove component when done
            if progress >= 1.0 {
                self.components[ClosureComponent.self] = nil
            }
        }
    }
}
