import Foundation
import RealityKit

extension Entity {
    /// The opacity value applied to the entity and its descendants.
    ///
    /// `OpacityComponent` is assigned to the entity if it doesn't already exist.
    var opacity: Float {
        get {
            return components[OpacityComponent.self]?.opacity ?? 1
        }
        set {
            if !components.has(OpacityComponent.self) {
                components[OpacityComponent.self] = OpacityComponent(opacity: newValue)
            } else {
                components[OpacityComponent.self]?.opacity = newValue
            }
        }
    }
    
    /// Fades the entity's opacity to a target value with optional animation.
    /// Returns after the animation completes, including any delay.
    ///
    /// - Parameters:
    ///   - targetOpacity: Target opacity value (0.0 to 1.0)
    ///   - duration: Animation duration in seconds (default: 1.0)
    ///   - delay: Optional delay before starting the animation (in seconds)
    ///   - timing: Animation timing curve (default: .easeInOut)
    ///   - waitForCompletion: If true, waits for the animation to complete before returning
    func fadeOpacity(to targetOpacity: Float,
                    duration: TimeInterval = 1.0,
                    delay: TimeInterval = 0,
                    timing: RealityKit.AnimationTimingFunction = .easeInOut,
                    waitForCompletion: Bool = false) async {
        // Handle delay first, even for immediate changes
        if delay > 0 {
            try? await Task.sleep(for: .seconds(delay))
        }
        
        // For non-animated changes (duration = 0), set immediately
        guard duration > 0 else {
            self.opacity = targetOpacity
            return
        }
        
        // Build and play the animation
        let startOpacity = self.opacity
        let fadeAnimation = FromToByAnimation(
            from: startOpacity,
            to: targetOpacity,
            duration: duration,
            timing: timing,
            bindTarget: .opacity
        )
        
        do {
            let animationResource = try AnimationResource.generate(with: fadeAnimation)
            playAnimation(animationResource)
            
            // Optionally wait for the animation to complete
            if waitForCompletion {
                try? await Task.sleep(for: .seconds(duration))
            }
        } catch {
            Logger.debug("⚠️ Could not generate opacity animation: \(error.localizedDescription)")
            // Fall back to immediate change
            self.opacity = targetOpacity
        }
    }
}
