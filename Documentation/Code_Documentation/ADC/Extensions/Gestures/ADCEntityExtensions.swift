# ADC Entity Extensions (Gestures)

This file extends the `Entity` class in RealityKit to add properties related to gesture handling.

## `Entity` Extension

*   **Purpose:** Adds computed properties to easily access and set the `ADCGestureComponent` and to get/set the scene position and orientation of an entity.
*   **Key Features:**
    *   `adcGestureComponent`: A computed property that gets or sets the `ADCGestureComponent` of an entity. This simplifies accessing and modifying the gesture component.
    *   `scenePosition`: A computed property that gets or sets the position of the entity relative to the scene's root.
    *   `sceneOrientation`: A computed property that gets or sets the orientation of the entity relative to the scene's root.

These extensions make it more convenient to work with gestures and entity transformations within the context of the ADC project. 