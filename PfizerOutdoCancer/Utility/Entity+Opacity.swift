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
    
    /// Sets the opacity value applied to the entity and its descendants with optional animation.
    ///
    /// `OpacityComponent` is assigned to the entity if it doesn't already exist.
    func setOpacity(_ opacity: Float, animated: Bool, duration: TimeInterval = 10.0, delay: TimeInterval = 0) {
        guard animated else {
            self.opacity = opacity
            return
        }

        if !components.has(OpacityComponent.self) {
            components[OpacityComponent.self] = OpacityComponent(opacity: 1)
        }

        let animation = FromToByAnimation(
            name: "Entity/setOpacity",
            to: opacity,
            duration: duration,
            timing: .linear,
            isAdditive: false,
            bindTarget: .opacity,
            delay: delay
        )
        
        do {
            let animationResource: AnimationResource = try .generate(with: animation)
            playAnimation(animationResource)
        } catch {
            assertionFailure("Could not generate animation: \(error.localizedDescription)")
        }
    }
} 
