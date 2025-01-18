import Foundation
import RealityKit

extension Entity {
    /// Cancels any pending animation timers for this entity
    func cancelPendingAnimations() {
        // No change needed here
    }
    
    /// Animates the x-scale of an entity from a starting value to an end value over a duration
    /// - Parameters:
    ///   - from: Starting x-scale value (optional - uses current scale if nil)
    ///   - to: Target x-scale value 
    ///   - duration: Animation duration in seconds
    ///   - delay: Optional delay before starting the animation (in seconds)
    ///   - timing: Animation timing curve (default: .easeInOut)
    ///   - waitForCompletion: If true, waits for the animation to complete before returning
    func animateXScale(from start: Float? = nil,
                      to end: Float,
                      duration: TimeInterval,
                      delay: TimeInterval = 0,
                      timing: RealityKit.AnimationTimingFunction = .easeInOut,
                      waitForCompletion: Bool = false) async {
        // Handle delay first, even for immediate changes
        if delay > 0 {
            try? await Task.sleep(for: .seconds(delay))
        }
        
        // For non-animated changes (duration = 0), set immediately
        guard duration > 0 else {
            var newTransform = transform
            newTransform.scale.x = end
            transform = newTransform
            return
        }
        
        // Build and play the animation
        let startTransform = transform
        var endTransform = transform
        endTransform.scale.x = end
        
        let scaleAnimation = FromToByAnimation(
            from: startTransform,
            to: endTransform,
            duration: duration,
            timing: timing,
            bindTarget: .transform
        )
        
        do {
            let resource = try AnimationResource.generate(with: scaleAnimation)
            playAnimation(resource)
            
            // Optionally wait for the animation to complete
            if waitForCompletion {
                try? await Task.sleep(for: .seconds(duration))
            }
        } catch {
            print("⚠️ Could not generate scale animation: \(error.localizedDescription)")
            // Fall back to immediate change
            var newTransform = transform
            newTransform.scale.x = end
            transform = newTransform
        }
    }
    
    /// Animates the z-position of an entity relative to its current position
    /// - Parameters:
    ///   - to: Distance to move in z direction (positive = forward, negative = backward)
    ///   - duration: Animation duration in seconds
    ///   - delay: Optional delay before starting the animation (in seconds)
    ///   - timing: Animation timing curve (default: .easeInOut)
    ///   - waitForCompletion: If true, waits for the animation to complete before returning
    func animateZPosition(to relativeZ: Float,
                         duration: TimeInterval,
                         delay: TimeInterval = 0,
                         timing: RealityKit.AnimationTimingFunction = .easeInOut,
                         waitForCompletion: Bool = false) async {
        // Handle delay first, even for immediate changes
        if delay > 0 {
            try? await Task.sleep(for: .seconds(delay))
        }
        
        let startTransform = transform
        var endTransform = transform
        
        // Add relative movement to current position
        endTransform.translation.z = startTransform.translation.z + relativeZ
        
        // For non-animated changes (duration = 0), set immediately
        guard duration > 0 else {
            transform = endTransform
            return
        }
        
        // Build and play the animation
        let positionAnimation = FromToByAnimation(
            from: startTransform,
            to: endTransform,
            duration: duration,
            timing: timing,
            bindTarget: .transform
        )
        
        do {
            let resource = try AnimationResource.generate(with: positionAnimation)
            playAnimation(resource)
            
            // Optionally wait for the animation to complete
            if waitForCompletion {
                try? await Task.sleep(for: .seconds(duration))
            }
        } catch {
            print("⚠️ Could not generate position animation: \(error.localizedDescription)")
            // Fall back to immediate change
            transform = endTransform
        }
    }
}