# ADC ModelEntity Extensions Documentation

This file extends the `ModelEntity` class in RealityKit with helper methods for updating material properties, specifically for PBR (Physically Based Rendering) and Shader Graph materials.

## `ModelEntity` Extension

*   **Purpose:** Provides convenience functions for modifying the visual appearance of `ModelEntity` instances by updating their materials.
*   **Key Features:**
    *   `updatePBRDiffuseColor(_:)`: Updates the base color (diffuse color) of a `PhysicallyBasedMaterial`. It handles cases where the material has an existing texture.
    *   `updatePBREmissiveColor(_:)`: Updates the emissive color of a `PhysicallyBasedMaterial`.
    *   `updateShaderGraphColor(parameterName:color:)`: Updates a color parameter in a `ShaderGraphMaterial`.
    *   `updateShaderGraphValue(parameterName:value:)`: Updates a float parameter in a `ShaderGraphMaterial`.

These extensions simplify the process of changing the colors and other visual properties of models, providing a more concise and readable way to interact with RealityKit's material system. They also include error handling and logging to help with debugging. The distinction between PBR and Shader Graph material updates is important, as they have different parameter structures. 