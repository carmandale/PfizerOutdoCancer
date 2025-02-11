# ADC Folder Documentation

This folder contains files related to the core Antibody-Drug Conjugate (ADC) functionality, including Entity-Component-System (ECS) implementations, extensions for RealityKit entities and materials, and gesture handling.

## Files

### `ADCBillboardSystem.swift`

*   **Purpose:** Implements a system to make entities face the camera (billboarding) or maintain a specific position relative to the camera.
*   **Key Components:**
    *   `ADCBillboardComponent`: A component that defines billboarding behavior, including offset, axis to follow, and initialization flags.
    *   `ADCBillboardSystem`: A RealityKit `System` that updates entity positions and orientations based on the `ADCBillboardComponent` and camera position.
*   **Functionality:**
    *   Allows entities to either always face the user (billboard) or maintain a position relative to the camera's movement.
    *   Provides options to control which axes the entity follows and whether the initial position is fixed.

### `ADCCameraSystem.swift`

*   **Purpose:** Manages the ARKit session and updates the position of a designated camera entity.
*   **Key Components:**
    *   `ADCCameraComponent`: A marker component to identify the camera entity.
    *   `ADCCameraSystem`: A RealityKit `System` that uses ARKit's `WorldTrackingProvider` to get the device's pose and update the camera entity's transform.
*   **Functionality:**
    *   Sets up and runs the ARKit session.
    *   Queries device pose from ARKit.
    *   Applies the device's transform to the camera entity, ensuring the virtual camera matches the real-world device position.

### `ADCGestureComponent.swift`

*   **Purpose:** Defines a component and associated state for handling drag, magnify, and rotate gestures on entities.
*   **Key Components:**
    *   `ADCEntityGestureState`: A class that holds the state of ongoing gestures (drag, magnify, rotate), including the targeted entity, start positions, and flags.
    *   `ADCGestureComponent`: A component that enables gesture handling on an entity, with options for dragging, pivoting, scaling, and rotating. Includes callbacks for gesture start/end events.
*   **Functionality:**
    *   Provides a unified way to handle different types of gestures on RealityKit entities.
    *   Supports both fixed dragging and pivot-based dragging (like moving windows).
    *   Allows scaling and 3D rotation gestures.
    *   Includes callbacks to notify when gestures start and end.

### `ADCProximitySystem.swift`

*   **Purpose:** Implements a system that scales entities based on their proximity to a source entity (usually the camera).
*   **Key Components:**
    *   `ADCProximityComponent`: Defines the scaling behavior, including minimum/maximum scale and proximity range.
    *   `ADCProximitySourceComponent`: A marker component to identify the source entity for proximity calculations.
    *   `ADCProximitySystem`: A RealityKit `System` that calculates distances and updates entity scales based on the `ADCProximityComponent`.
*   **Functionality:**
    *   Scales entities up or down based on their distance from a source entity.
    *   Provides control over the minimum and maximum scale and the distance range for scaling.

### `ADCSimpleBillboardSystem.swift`

*   **Purpose:** A simplified version of `ADCBillboardSystem` that only handles making entities face the camera.
*   **Key Components:**
    *   `ADCSimpleBillboardComponent`: A marker component to enable simple billboarding.
    *   `ADCSimpleBillboardSystem`: A RealityKit `System` that orients entities to face the camera.
*   **Functionality:**
    *   Makes entities always face the camera, useful for 2D elements or simple labels in a 3D scene.

### `Extensions` Folder
This folder contains extensions to core swift and RealityKit classes. See the documentation file in that folder.

### `Models` Folder
This folder contains models used by the ADC system. See the documentation file in that folder.

### `Views` Folder
This folder contains the SwiftUI views used by the ADC system. See the documentation file in that folder. 