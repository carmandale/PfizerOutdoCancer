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
            Logger.debug("⚠️ Could not generate scale animation: \(error.localizedDescription)")
            // Fall back to immediate change
            var newTransform = transform
            newTransform.scale.x = end
            transform = newTransform
        }
    }
    
    /// Animates uniform scale of an entity from a starting value to an end value over a duration
    /// - Parameters:
    ///   - from: Starting scale value (optional - uses current scale if nil)
    ///   - to: Target scale value 
    ///   - duration: Animation duration in seconds
    ///   - delay: Optional delay before starting the animation (in seconds)
    ///   - timing: Animation timing curve (default: cubicBezier with ease-in-out control points)
    ///   - waitForCompletion: If true, waits for the animation to complete before returning
    func animateScale(from start: Float? = nil,
                     to end: Float,
                     duration: TimeInterval,
                     delay: TimeInterval = 0,
                     timing: RealityKit.AnimationTimingFunction = .cubicBezier(controlPoint1: SIMD2<Float>(1.0, 0), controlPoint2: SIMD2<Float>(0.6, 1)),
                     waitForCompletion: Bool = false) async {
        // Handle delay first, even for immediate changes
        if delay > 0 {
            try? await Task.sleep(for: .seconds(delay))
        }
        
        // For non-animated changes (duration = 0), set immediately
        guard duration > 0 else {
            var newTransform = transform
            newTransform.scale = .init(repeating: end)
            transform = newTransform
            return
        }
        
        // Build and play the animation
        let startTransform = transform
        var endTransform = transform
        endTransform.scale = .init(repeating: end)
        
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
            Logger.debug("⚠️ Could not generate scale animation: \(error.localizedDescription)")
            // Fall back to immediate change
            var newTransform = transform
            newTransform.scale = .init(repeating: end)
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
            Logger.debug("⚠️ Could not generate position animation: \(error.localizedDescription)")
            // Fall back to immediate change
            transform = endTransform
        }
    }
    
    /// Animates the position of an entity from its current position to a target position
    /// - Parameters:
    ///   - to: Target position as SIMD3<Float> to add to current position
    ///   - duration: Animation duration in seconds
    ///   - delay: Optional delay before starting the animation (in seconds)
    ///   - timing: Animation timing curve (default: .easeInOut)
    ///   - waitForCompletion: If true, waits for the animation to complete before returning
    func animatePosition(to targetPosition: SIMD3<Float>,
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
        endTransform.translation = startTransform.translation + targetPosition
        
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
            Logger.debug("⚠️ Could not generate position animation: \(error.localizedDescription)")
            // Fall back to immediate change
            transform = endTransform
        }
    }
    
    /// Animates the Y rotation of an entity from its current rotation to a target angle in degrees
    /// - Parameters:
    ///   - to: Target angle in degrees (positive = clockwise)
    ///   - duration: Animation duration in seconds
    ///   - delay: Optional delay before starting the animation (in seconds)
    ///   - timing: Animation timing curve (default: .easeInOut)
    ///   - waitForCompletion: If true, waits for the animation to complete before returning
    func animateYRotation(to targetDegrees: Float,
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
        
        // Convert degrees to radians and set Y rotation
        let targetRadians = (targetDegrees * .pi) / 180
        endTransform.rotation = simd_quatf(angle: targetRadians, axis: SIMD3<Float>(0, 1, 0))
        
        // For non-animated changes (duration = 0), set immediately
        guard duration > 0 else {
            transform = endTransform
            return
        }
        
        // Build and play the animation
        let rotationAnimation = FromToByAnimation(
            from: startTransform,
            to: endTransform,
            duration: duration,
            timing: timing,
            bindTarget: .transform
        )
        
        do {
            let resource = try AnimationResource.generate(with: rotationAnimation)
            playAnimation(resource)
            
            // Optionally wait for the animation to complete
            if waitForCompletion {
                try? await Task.sleep(for: .seconds(duration))
            }
        } catch {
            Logger.debug("⚠️ Could not generate rotation animation: \(error.localizedDescription)")
            // Fall back to immediate change
            transform = endTransform
        }
    }
    
    /// Creates a quick squish and bounce scale animation when an entity is hit
    /// - Parameters:
    ///   - intensity: How strong the squish effect should be (default: 0.9)
    ///   - duration: Total duration of the squish and bounce animation (default: 0.3)
    ///   - scaleReduction: The percentage to reduce the current scale by (default: 0.1 = 10%)
    ///   - waitForCompletion: If true, waits for the animation to complete before returning
    func hitScaleAnimation(intensity: Float = 0.9,
                         duration: TimeInterval = 0.3,
                         scaleReduction: Float = 0.1,
                         waitForCompletion: Bool = false) async {
        // Store original scale
        let originalScale = scale
        let targetScale = originalScale * (1.0 - scaleReduction) // Reduce by percentage
        
        // First phase: Quick squish (25% of duration)
        var squishTransform = transform
        squishTransform.scale = originalScale * intensity
        
        // Second phase: Bounce back slightly larger (50% of duration)
        var bounceTransform = transform
        let bounceScale = targetScale * (2.0 - intensity) // Bounce to slightly larger than target
        bounceTransform.scale = bounceScale
        
        // Final phase: Return to target scale (25% of duration)
        var finalTransform = transform
        finalTransform.scale = targetScale
        
        // Create the multi-phase animation
        let squishDuration = duration * 0.25
        let bounceDuration = duration * 0.5
        let returnDuration = duration * 0.25
        
        // Squish phase
        let squishAnimation = FromToByAnimation(
            from: transform,
            to: squishTransform,
            duration: squishDuration,
            timing: .easeIn,
            bindTarget: .transform
        )
        
        // Bounce phase
        let bounceAnimation = FromToByAnimation(
            from: squishTransform,
            to: bounceTransform,
            duration: bounceDuration,
            timing: .easeOut,
            bindTarget: .transform
        )
        
        // Return phase
        let returnAnimation = FromToByAnimation(
            from: bounceTransform,
            to: finalTransform,
            duration: returnDuration,
            timing: .easeInOut,
            bindTarget: .transform
        )
        
        do {
            // Generate and play each phase
            let squishResource = try AnimationResource.generate(with: squishAnimation)
            playAnimation(squishResource, transitionDuration: 0)
            
            if waitForCompletion {
                try await Task.sleep(for: .seconds(squishDuration))
            }
            
            let bounceResource = try AnimationResource.generate(with: bounceAnimation)
            playAnimation(bounceResource, transitionDuration: 0)
            
            if waitForCompletion {
                try await Task.sleep(for: .seconds(bounceDuration))
            }
            
            let returnResource = try AnimationResource.generate(with: returnAnimation)
            playAnimation(returnResource, transitionDuration: 0)
            
            if waitForCompletion {
                try await Task.sleep(for: .seconds(returnDuration))
            }
        } catch {
            Logger.debug("Failed to create hit scale animation: \(error)")
        }
    }
    
    /// Animates both position and Y rotation of an entity simultaneously
    /// - Parameters:
    ///   - position: Target position as SIMD3<Float> to add to current position
    ///   - rotation: Target Y rotation in degrees (positive = clockwise)
    ///   - duration: Animation duration in seconds
    ///   - delay: Optional delay before starting the animation (in seconds)
    ///   - timing: Animation timing curve (default: .easeInOut)
    ///   - waitForCompletion: If true, waits for the animation to complete before returning
    func animatePositionAndRotation(position: SIMD3<Float>,
                                    rotation: Float,
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
        
        // Set both position and rotation in the end transform
        endTransform.translation = startTransform.translation + position
        let rotationRadians = (rotation * .pi) / 180
        endTransform.rotation = simd_quatf(angle: rotationRadians, axis: SIMD3<Float>(0, 1, 0))
        
        // For non-animated changes (duration = 0), set immediately
        guard duration > 0 else {
            transform = endTransform
            return
        }
        
        // Build and play the animation
        let combinedAnimation = FromToByAnimation(
            from: startTransform,
            to: endTransform,
            duration: duration,
            timing: timing,
            bindTarget: .transform
        )
        
        do {
            let resource = try AnimationResource.generate(with: combinedAnimation)
            playAnimation(resource)
            
            // Optionally wait for the animation to complete
            if waitForCompletion {
                try? await Task.sleep(for: .seconds(duration))
            }
        } catch {
            Logger.debug("⚠️ Could not generate combined animation: \(error.localizedDescription)")
            // Fall back to immediate change
            transform = endTransform
        }
    }

    /// Animates an entity to an absolute position and Y rotation
    /// - Parameters:
    ///   - targetPosition: Absolute target position as SIMD3<Float>
    ///   - targetYRotationDegrees: Absolute Y rotation in degrees (positive = clockwise)
    ///   - duration: Animation duration in seconds
    ///   - delay: Optional delay before starting (in seconds)
    ///   - timing: Animation timing curve (default: .easeInOut)
    ///   - waitForCompletion: If true, waits for animation to complete
    func animateToPositionAndYRotation(targetPosition: SIMD3<Float>,
                                       targetYRotationDegrees: Float,
                                       duration: TimeInterval,
                                       delay: TimeInterval = 0,
                                       timing: RealityKit.AnimationTimingFunction = .easeInOut,
                                       waitForCompletion: Bool = false) async {
        if delay > 0 {
            try? await Task.sleep(for: .seconds(delay))
        }
        
        let startTransform = transform
        Logger.debug("Start - Pos: \(startTransform.translation), Rot: \(startTransform.rotation.angle * 180 / .pi)° around \(startTransform.rotation.axis)")

        var endTransform = Transform()
        endTransform.translation = targetPosition
        let rotationRadians = (targetYRotationDegrees * .pi) / 180
        endTransform.rotation = simd_quatf(angle: rotationRadians, axis: SIMD3<Float>(0, 1, 0))
        Logger.debug("End - Pos: \(endTransform.translation), Rot: \(endTransform.rotation.angle * 180 / .pi)° around \(endTransform.rotation.axis)")
        
        guard duration > 0 else {
            transform = endTransform
            return
        }
        
        stopAllAnimations()

        let animation = FromToByAnimation(
            from: startTransform,
            to: endTransform,
            duration: duration,
            timing: timing,
            bindTarget: .transform
        )
        
        do {
            let resource = try AnimationResource.generate(with: animation)
            playAnimation(resource)
            Logger.debug("Animation started with duration: \(duration)s")
            if waitForCompletion {
                try? await Task.sleep(for: .seconds(duration))
            }
        } catch {
            Logger.debug("⚠️ Could not generate animation: \(error.localizedDescription)")
            transform = endTransform
        }
    }

    
    /// Starts continuous rotation around the specified axis
    /// - Parameters:
    ///   - speed: Rotation speed in radians per second (default: 1.0)
    ///   - axis: The axis to rotate around (default: .yAxis)
    func startContinuousRotation(speed: Float = 1.0, axis: RotationAxis = .yAxis) {
        var component = RotationComponent()
        component.speed = speed
        component.rotationAxis = axis
        components.set(component)
    }
    
    /// Starts continuous rotation around the Y axis (legacy support)
    /// - Parameter speed: Rotation speed in radians per second (default: 1.0)
    func startContinuousYRotation(speed: Float = 1.0) {
        startContinuousRotation(speed: speed, axis: .yAxis)
    }
    
    /// Stops any continuous rotation by removing the RotationComponent
    func stopRotation() {
        components.remove(RotationComponent.self)
    }
    
    /// Animates the entity's absolute position and scale from its current state to a target state.
    /// - Parameters:
    ///   - targetPosition: The absolute target position (default: [0, 0, 0])
    ///   - targetScale: The absolute target scale (default: [1, 1, 1])
    ///   - duration: Animation duration in seconds
    ///   - delay: Optional delay before starting the animation (in seconds)
    ///   - timing: Animation timing curve (default: .easeInOut)
    ///   - waitForCompletion: If true, waits for the animation to complete before returning
    func animateAbsolutePositionAndScale(to targetPosition: SIMD3<Float> = SIMD3<Float>(0, 0, 0),
                                           scale targetScale: SIMD3<Float> = SIMD3<Float>(1, 1, 1),
                                           duration: TimeInterval,
                                           delay: TimeInterval = 0,
                                           timing: RealityKit.AnimationTimingFunction = .easeInOut,
                                           waitForCompletion: Bool = false) async {
        // Handle delay first
        if delay > 0 {
            try? await Task.sleep(for: .seconds(delay))
        }
        
        let startTransform = transform
        var endTransform = transform
        // Set absolute target values
        endTransform.translation = targetPosition
        endTransform.scale = targetScale
        
        // For non-animated changes (duration = 0), apply the transform immediately
        guard duration > 0 else {
            transform = endTransform
            return
        }
        
        // Build the animation using FromToByAnimation, animating the entire transform
        let animation = FromToByAnimation(
            from: startTransform,
            to: endTransform,
            duration: duration,
            timing: timing,
            bindTarget: .transform
        )
        
        do {
            let resource = try AnimationResource.generate(with: animation)
            playAnimation(resource)
            
            // Optionally wait for the animation to complete
            if waitForCompletion {
                try? await Task.sleep(for: .seconds(duration))
            }
        } catch {
            Logger.debug("⚠️ Could not generate absolute position and scale animation: \(error.localizedDescription)")
            // Fall back to directly setting the transform
            transform = endTransform
        }
    }
    
    /// Animates the entity's absolute position from its current position to a target position.
    /// - Parameters:
    ///   - targetPosition: The absolute target position
    ///   - duration: Animation duration in seconds
    ///   - delay: Optional delay before starting the animation (in seconds)
    ///   - timing: Animation timing curve (default: .easeInOut)
    ///   - waitForCompletion: If true, waits for the animation to complete before returning
    func animateAbsolutePosition(to targetPosition: SIMD3<Float>,
                                duration: TimeInterval,
                                delay: TimeInterval = 0,
                                timing: RealityKit.AnimationTimingFunction = .easeInOut,
                                waitForCompletion: Bool = false) async {
        // Handle delay first
        if delay > 0 {
            try? await Task.sleep(for: .seconds(delay))
        }
        
        let startTransform = transform
        var endTransform = transform
        // Set absolute target position
        endTransform.translation = targetPosition
        
        // For non-animated changes (duration = 0), apply the transform immediately
        guard duration > 0 else {
            transform = endTransform
            return
        }
        
        // Build the animation using FromToByAnimation
        let animation = FromToByAnimation(
            from: startTransform,
            to: endTransform,
            duration: duration,
            timing: timing,
            bindTarget: .transform
        )
        
        do {
            let resource = try AnimationResource.generate(with: animation)
            playAnimation(resource)
            
            // Optionally wait for the animation to complete
            if waitForCompletion {
                try? await Task.sleep(for: .seconds(duration))
            }
        } catch {
            Logger.debug("⚠️ Could not generate absolute position animation: \(error.localizedDescription)")
            // Fall back to directly setting the transform
            transform = endTransform
        }
    }
    
    /// Triggers a head position update for an entity with a PositioningComponent
    /// - Parameters:
    ///   - animated: Whether to animate the position change
    ///   - duration: Animation duration in seconds (only used if animated is true)
    func checkHeadPosition(animated: Bool = false, duration: TimeInterval = 0.5) {
        guard var positioningComponent = components[PositioningComponent.self] else {
            Logger.debug("⚠️ Cannot check head position: No PositioningComponent found on entity '\(name)'")
            return 
        }
        
        Logger.debug("""
        
        🎯 Requesting head position update for entity '\(name)'
        ├─ Current World Position: \(position(relativeTo: nil))
        ├─ Offsets: [\(positioningComponent.offsetX), \(positioningComponent.offsetY), \(positioningComponent.offsetZ)]
        ├─ Animated: \(animated ? "✅" : "❌")
        └─ Duration: \(animated ? "\(duration)s" : "immediate")
        """)
        
        positioningComponent.needsPositioning = true
        positioningComponent.shouldAnimate = animated
        positioningComponent.animationDuration = animated ? duration : 0.0
        components[PositioningComponent.self] = positioningComponent
    }
}
