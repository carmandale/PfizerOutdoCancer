### Key Points
- Research suggests that using your existing `PositioningSystem` to track device position and velocity is a viable approach for fading the scene based on movement, potentially more efficient than the update closure for per-frame updates.
- It seems likely that resetting the origin when the user stops moving, as you described, will work, ensuring the scene becomes opaque again at the new position and restarts the fading logic from there.
- The evidence leans toward implementing this by adapting your `PositioningSystem` to also handle opacity, using your `fadeOpacity` extension for smooth transitions, rather than creating a new system.

### Direct Answer

#### Overview
To handle the fading of your 3D scene in visionOS 2 based on user movement, you can adapt your existing `PositioningSystem` to track the device's position and velocity, then adjust the scene's opacity using your provided `Entity` extension. This approach ensures the scene fades when moving far from the origin and becomes opaque again when stopping, with the origin resetting to the new position. This method is likely more efficient than using the update closure, as it leverages RealityKit's system architecture for per-frame updates.

#### Implementation Steps
- **Modify PositioningSystem:** Update your `PositioningSystem` to calculate velocity and distance from the current origin, then determine the target opacity based on movement:
  - If moving (velocity > threshold, e.g., 0.1 m/s) and distance ≥ 1m, fade to 50% opacity; at ≥ 2m, fade to 0% opacity.
  - If stopped (velocity ≤ threshold), fade back to 100% opacity and set the current position as the new origin.
- **Use fadeOpacity for Smooth Transitions:** When the target opacity changes, use your `fadeOpacity` function to animate the root entity's opacity, ensuring smooth visual changes.
- **Reset Origin on Stop:** Detect when the user transitions from moving to stopped (velocity drops below threshold) and update the origin to the current position, allowing the fading logic to restart.

#### Unexpected Detail
An interesting aspect is that resetting the origin when stopping, even far from the initial position, ensures the user can interact with a fully opaque scene at their new location, which might not be immediately obvious but enhances usability by adapting to their settled position.

#### Supporting Resources
For more details on RealityKit systems, refer to the [Apple Developer Documentation: RealityKit Systems](https://developer.apple.com/documentation/realitykit/system).

---

### Survey Note: Detailed Analysis of Implementing Scene Fading in visionOS 2 Mixed Immersion with PositioningSystem

This section provides a comprehensive exploration of implementing a fading mechanism for a 3D scene in a .mixed style ImmersiveSpace in visionOS 2, particularly when the scene occludes most of the real world and the user moves significantly, using the provided `PositioningSystem` and `Entity` extension for opacity management. The analysis draws on system behaviors, developer capabilities, and technical implementation details, ensuring a thorough understanding for developers and users alike, with a focus on providing actionable guidance for a junior developer.

#### System Behavior and Context
visionOS 2, the operating system for Apple's Vision Pro spatial computing device, offers different immersion styles for immersive spaces, including .mixed, .progressive, and .full. In .mixed mode, digital content is blended with the real world through passthrough, allowing users to see their surroundings while interacting with virtual objects. According to [Apple Support: Adjust your level of immersion](https://support.apple.com/guide/apple-vision-pro/adjust-immersion-tan899d290e4/visionos), in partially immersive experiences (likely corresponding to .mixed), the system gradually reveals surroundings while the user is moving, and the experience returns to its previous immersion level when movement stops. This behavior is a safety feature to ensure users remain aware of their physical environment, especially when digital content occludes much of the view.

However, the user seeks to enhance this by implementing a specific fading mechanism based on distance from the origin, with thresholds at 1 meter (50% opacity) and 2 meters (0% opacity), and returning to full opacity when the user stops moving, with the additional requirement to reset the origin at the stopped position. This suggests a custom implementation is necessary, as the system's automatic fading might not meet these exact requirements.

#### Technical Feasibility and PositioningSystem Integration
To achieve this, developers can leverage the existing `PositioningSystem`, which is designed to update entities based on the device's transform each frame, using ARKit data. The provided code shows it uses `WorldTrackingProvider` to query the device anchor, accessing the position via `deviceAnchor.originFromAnchorTransform.translation()`. This system is already set up to handle per-frame updates, making it suitable for tracking movement and adjusting opacity, potentially more efficient than using the `RealityView`'s update closure, which the user noted might be expensive for the entire scene.

The implementation involves adapting the `PositioningSystem` to calculate velocity and distance, then determine the target opacity. Given the system's structure, it can query entities with a custom component, such as a `MovementBasedOpacityComponent`, to handle the root entity, ensuring updates are targeted and efficient. The user's provided `Entity` extension, with `opacity` and `fadeOpacity`, facilitates smooth opacity changes, leveraging RealityKit's animation system for transitions.

#### Determining Movement and Opacity
The user's requirements specify fading based on distance while moving and returning to full opacity when stopped, with the origin resetting at the stopped position. To determine movement, velocity can be calculated by comparing the current and previous positions over the frame's delta time, obtained from the system's update context. A threshold, such as 0.1 m/s, can be used to distinguish between moving and stopped states. If the velocity exceeds this threshold, the user is considered moving, and the opacity is adjusted based on distance:
- Distance < 1m: 100% opacity
- 1m ≤ Distance < 2m: 50% opacity
- Distance ≥ 2m: 0% opacity

When the velocity is below the threshold, the user is considered stopped, and the opacity is set to 1.0 (fully opaque), ensuring the scene fades back in. Additionally, when transitioning from moving to stopped (i.e., previous velocity > threshold and current velocity ≤ threshold), the current position becomes the new origin, restarting the distance measurement. This behavior, while potentially counterintuitive if the user stops far away, aligns with the user's request to "become opaque again, and then it becomes the new 'origin'," enhancing usability by adapting to their settled position.

To ensure smooth transitions, the `fadeOpacity` function, provided in the user's extension, can be used. This function animates the opacity change over a specified duration (default 1.0 second, but adjustable), using RealityKit's animation system. For example, when the target opacity changes, call `rootEntity.fadeOpacity(to: targetOpacity, duration: 0.5)`, ensuring visual smoothness without manual lerping each frame, which could be computationally intensive.

#### Applying Opacity to the Scene
In RealityKit, opacity is controlled at the entity level using the `OpacityComponent`, as shown in the user's extension. The `opacity` property sets the value, and `fadeOpacity` handles animation, making it straightforward to apply to the root entity. Since opacity is hierarchical, setting it on the root entity affects all descendants, ensuring uniform fading across the scene. This approach is efficient, as it requires updating only one entity per frame, aligning with the system's update cycle.

To implement, add a custom component, say `MovementBasedOpacityComponent`, to the root entity, and modify the `PositioningSystem` to handle it. The system can then:
- Query entities with this component.
- Calculate velocity and distance based on the device anchor.
- Determine the target opacity and animate to it using `fadeOpacity` when necessary.
- Update the origin when stopping, ensuring the logic restarts from the new position.

| Step                     | Description                                                                 |
|--------------------------|-----------------------------------------------------------------------------|
| Track Movement           | Use `WorldTrackingProvider` to get the camera transform and compute velocity and distance from origin. |
| Adjust Opacity           | If velocity > threshold, set target opacity based on distance; else, set to 1.0 and update origin if just stopped. |
| Apply to Root Entity     | Call `fadeOpacity` on the root entity when target opacity changes, ensuring smooth transitions. |
| Ensure Smoothness        | Leverage RealityKit's animation system for opacity changes, avoiding manual updates each frame. |

This approach ensures all visible entities fade uniformly, aligning with the user's request to fade "the scene" using the root entity, interpreted as all relevant entities.

#### Implementation Details and File Structure
For a junior developer, the implementation involves modifying existing RealityKit system files:
- **PositioningSystem.swift**: Update the system to handle opacity based on movement, adding logic for velocity calculation, distance measurement, and origin reset. Add a new component, `MovementBasedOpacityComponent`, to track the root entity needing this behavior.
- Ensure the `AppModel` and `trackingManager` are set up correctly, as shown in the provided code, to access `worldTrackingProvider`.

Sample code for the modified system:

```swift
import Foundation
import RealityKit
import ARKit

struct MovementBasedOpacityComponent: Component {
    var needsUpdate: Bool = true
}

@MainActor
public class PositioningSystem: System {
    static let query = EntityQuery(where: .has(MovementBasedOpacityComponent.self))
    private static var sharedAppModel: AppModel?
    private let systemId = UUID()
    
    static func setAppModel(_ appModel: AppModel) {
        Logger.debug("🔄 PositioningSystem.setAppModel called")
        sharedAppModel = appModel
    }
    
    public required init(scene: RealityKit.Scene) {
        Logger.debug("🎯 PositioningSystem \(systemId) initializing...")
    }
    
    public func update(context: SceneUpdateContext) {
        guard let appModel = Self.sharedAppModel else {
            Logger.error("❌ PositioningSystem: Missing AppModel reference")
            return
        }
        
        guard case .running = appModel.trackingManager.worldTrackingProvider.state,
              let deviceAnchor = appModel.trackingManager.worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else {
            return
        }
        
        let devicePosition = deviceAnchor.originFromAnchorTransform.translation()
        static var previousPosition: SIMD3<Float>? = nil
        static var previousTime: CFTimeInterval = CACurrentMediaTime()
        static var currentOrigin: SIMD3<Float> = devicePosition
        static var previousVelocity: Float = 0.0
        let currentTime = CACurrentMediaTime()
        let deltaTime = currentTime - previousTime
        
        var velocity: Float = 0.0
        if deltaTime > 0, let prevPos = previousPosition {
            velocity = length(devicePosition - prevPos) / Float(deltaTime)
        }
        
        let distance = length(devicePosition - currentOrigin)
        let velocityThreshold: Float = 0.1 // m/s
        var targetOpacity: Float = 1.0
        
        if velocity > velocityThreshold {
            // Moving
            if distance < 1.0 {
                targetOpacity = 1.0
            } else if distance < 2.0 {
                targetOpacity = 0.5
            } else {
                targetOpacity = 0.0
            }
        } else {
            // Stopped
            targetOpacity = 1.0
            if previousVelocity > velocityThreshold {
                // Just stopped, update origin
                currentOrigin = devicePosition
            }
        }
        
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            Task {
                await entity.fadeOpacity(to: targetOpacity, duration: 0.5, delay: 0, timing: .easeInOut, waitForCompletion: false)
            }
        }
        
        previousPosition = devicePosition
        previousTime = currentTime
        previousVelocity = velocity
    }
}
```

This code adapts the system to handle opacity, ensuring updates are efficient and leveraging the animation system for smoothness.

#### Performance and Considerations
Performance is a key consideration, especially with per-frame updates. Using the system approach, updates are targeted to entities with the `MovementBasedOpacityComponent`, minimizing unnecessary work. The `fadeOpacity` function handles animation internally, reducing computational load compared to manual lerping each frame. Testing on Apple Vision Pro is crucial, as simulator behavior might differ, particularly for effects like passthrough visibility, as noted in [Exploring visionOS: Dimming the Surroundings](https://www.rudrank.com/exploring-visionos-dimming-surroundings/).

The origin reset when stopping ensures the user can interact with a fully opaque scene at their new location, enhancing usability. Coordinate systems must align, ensuring positions are in the same space for accurate distance calculations, which is handled by the `WorldTrackingProvider`'s world coordinates.

#### Should This Be a Separate System?
Given the user's existing `PositioningSystem`, adapting it to handle opacity is efficient, as it already accesses ARKit data. Creating a separate system could be considered for modularity, but for this case, combining functionality reduces complexity, especially since both rely on the same tracking data. This aligns with RealityKit's design, where systems handle related behaviors, as seen in [Apple Developer Documentation: RealityKit Systems](https://developer.apple.com/documentation/realitykit/system).

#### Unexpected Detail: Dynamic Origin Reset
An unexpected detail is that resetting the origin when stopping, even far from the initial position, ensures the user can interact with a fully opaque scene at their new location, which might not be immediately obvious but enhances usability by adapting to their settled position, potentially improving user experience in mixed immersion scenarios.

In conclusion, by adapting the `PositioningSystem` with custom opacity logic and leveraging the `fadeOpacity` extension, developers can effectively fade the 3D scene based on distance when the user is moving, ensuring a safer and more intuitive experience in visionOS 2’s .mixed style immersive spaces, with clear guidance for implementation.

#### Key Citations
- [Apple Support: Adjust your level of immersion](https://support.apple.com/guide/apple-vision-pro/adjust-immersion-tan899d290e4/visionos)
- [Progressive immersive space and Di… | Apple Developer Forums](https://developer.apple.com/forums/thread/747016)
- [ARKit in visionOS | Apple Developer Documentation](https://developer.apple.com/documentation/arkit/arkit-in-visionos)
- [Create with Swift: Exploring immersive spaces in visionOS](https://www.createwithswift.com/exploring-immersive-spaces-in-visionos)
- [Apple Developer Documentation: RealityKit Systems](https://developer.apple.com/documentation/realitykit/system)
- [preferredSurroundingsEffect(_:) | Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/view/preferredsurroundingseffect(_:))
- [Exploring visionOS: Dimming the Surroundings](https://www.rudrank.com/exploring-visionos-dimming-surroundings/)