# ADC Gesture Extensions

This file provides extensions to SwiftUI's `Gesture` protocol to integrate with the custom `ADCGestureComponent`.

## `Gesture` Extensions

*   **Purpose:** Connects SwiftUI gestures (Drag, Magnify, Rotate) to the `ADCGestureComponent` to handle gesture events.
*   **Key Features:**
    *   `useADCGestureComponent()`: This extension is added to `Gesture` where the `Value` is `EntityTargetValue<DragGesture.Value>`, `EntityTargetValue<MagnifyGesture.Value>`, or `EntityTargetValue<RotateGesture3D.Value>`. It connects the `onChanged` and `onEnded` events of the gesture to the corresponding methods in the `ADCGestureComponent`.

These extensions provide a bridge between SwiftUI's gesture system and the custom gesture handling logic defined in `ADCGestureComponent`, allowing for a more declarative and streamlined way to manage gestures on RealityKit entities. 