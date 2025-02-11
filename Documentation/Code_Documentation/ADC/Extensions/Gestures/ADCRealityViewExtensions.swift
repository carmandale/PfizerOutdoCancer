# ADC RealityView Extensions (Gestures)

This file extends the `RealityView` class in RealityKit to add convenience methods for installing gestures.

## `RealityView` Extension

*   **Purpose:** Provides a simple way to install a set of predefined gestures (drag, magnify, rotate) on a `RealityView`.
*   **Key Features:**
    *   `installGestures()`: This method adds simultaneous drag, magnify, and rotate gestures to the `RealityView`. It uses the `useADCGestureComponent()` extension to connect these gestures to the `ADCGestureComponent`.
    *   `dragGesture`, `magnifyGesture`, `rotateGesture`: These computed properties define the specific gesture configurations for drag, magnify, and rotate, respectively. They use `targetedToAnyEntity()` to make the gestures apply to any entity within the `RealityView`.

This extension simplifies the setup of common gestures on a `RealityView`, making it easier to add interactivity to RealityKit scenes. 