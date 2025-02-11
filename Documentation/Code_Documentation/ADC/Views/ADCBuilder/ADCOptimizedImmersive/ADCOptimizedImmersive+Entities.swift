# ADCOptimizedImmersive+Entities Documentation

This file is an extension of the `ADCOptimizedImmersive` struct, responsible for managing the 3D entities within the immersive scene.

## `ADCOptimizedImmersive` Extension (Entities)

*   **Purpose:** Handles the loading, preparation, positioning, and cleanup of RealityKit entities used in the ADC building process. This includes the antibody, linkers, payloads, and target entities.
*   **Key Features:**
    *   **Entity Properties:**
        *   `mainEntity`: The root entity for the scene.
        *   `mainViewEntity`:  An entity to hold the main 2D UI (ADCBuilderView).
        *   `antibodyRootEntity`: The root entity for the antibody model.
        *   `antibodyEntity`: The `ModelEntity` representing the antibody itself.
        *   `linkerEntity`, `payloadEntity`: Entities used as targets for placing linkers and payloads.
        *   `workingLinker`, `workingPayloadInner`, `workingPayloadOuter`:  `ModelEntity` instances representing the currently interactive linker and payload.
        *   `adcLinkers`, `adcPayloadsInner`, `adcPayloadsOuter`: Arrays to store all linker and payload entities.
        *   `adcAttachmentEntity`, `linkerAttachmentEntity`, `payloadAttachmentEntity`:  `ViewAttachmentEntity` instances for attaching SwiftUI views.
        *   `initialLinkerPosition`, `initialPayloadPosition`: Store the initial positions of the linker and payload entities.
        *   `originalAntibodyMaterial`, `originalLinkerMaterial`, `originalPayloadInnerMaterial`, `originalPayloadOuterMaterial`: Store the original materials of the entities to allow for restoration.
        *   `outlineMaterial`:  A `ShaderGraphMaterial` used to create an outline effect.
        *   `adcSortGroup`: A `ModelSortGroup` to manage the rendering order of ADC components.

    *   **Entity Preparation Functions:**
        *   `prepareAntibodyEntities()`: Loads the antibody model, sets up its initial position and orientation, applies the outline material, and configures gesture and audio components.
        *   `prepareLinkerEntities()`: Finds the linker entities within the antibody model, stores their original materials, and applies the outline material.
        *   `preparePayloadEntities()`: Finds the inner and outer payload entities, stores their original materials, applies the outline material, and sets up their transforms.
        *   `prepareTargetEntities(antibodyScene:)`:  Finds the target entities (for linker and payload placement), sets up gesture components, attaches audio, and applies the outline material.
    *   **Cleanup Function:**
        *   `cleanup()`: Resets the data model, stops audio playback, removes entities from the scene, clears entity references, and releases resources. This is crucial for managing memory and preventing memory leaks when the immersive space is dismissed.

This extension is the core of the 3D scene management for the ADC builder. It handles the complex tasks of loading and configuring the various 3D models, setting up their interactions, and ensuring proper cleanup when the scene is no longer needed. The use of helper functions and clear organization makes the code more maintainable and easier to understand. 