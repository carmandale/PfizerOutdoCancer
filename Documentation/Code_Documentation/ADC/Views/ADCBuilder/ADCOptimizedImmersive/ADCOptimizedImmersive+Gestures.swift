# ADCOptimizedImmersive+Gestures Documentation

This file is an extension of the `ADCOptimizedImmersive` struct, handling gesture interactions within the immersive scene.

## `ADCOptimizedImmersive` Extension (Gestures)

*   **Purpose:** Defines and configures the gesture interactions for the ADC building process, specifically for dragging, rotating, and scaling entities.
*   **Key Features:**
    *   **Gesture Component Creation Functions:**
        *   `createGestureComponent()`: Creates an `ADCGestureComponent` for the main antibody entity, enabling rotation and disabling drag/scale. It includes callbacks to manage attachment visibility during gestures.
        *   `createLinkerGestureComponent(linkerEntity:linkerTarget:)`: Creates an `ADCGestureComponent` for the draggable linker entity. It enables dragging, disables rotation/scale, and includes logic to handle the placement of linkers onto the antibody.  It also manages proximity-based interactions.
        *   `createPayloadGestureComponent(payloadEntity:payloadTarget:)`: Creates an `ADCGestureComponent` for the draggable payload entity, similar to the linker gesture component but with logic for payload placement.
    *   **Gesture Handling Logic:**
        *   The `onDragEnded` callbacks in the linker and payload gesture components check for proximity to the target attachment points. If close enough, they trigger the attachment logic, apply the selected colors, play a pop sound, and update the `ADCDataModel`.
        *   The `handleFinalEntityPlacement(entityType:workingEntity:savedPosition:nextStep:)` function handles the final placement of linkers and payloads, including playing sounds, advancing the build step, and playing voice-overs.

This extension encapsulates the gesture interaction logic, providing a clean separation between the gesture setup and the actions performed when gestures occur. The use of the `ADCGestureComponent` and its callbacks allows for a flexible and customizable gesture handling system. 