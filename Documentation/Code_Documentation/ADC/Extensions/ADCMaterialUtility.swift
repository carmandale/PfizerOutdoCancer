# ADC Material Utility Documentation

This file provides extensions to `ModelEntity` to simplify applying specific ADC-related colors to materials.

## `ModelEntity` Extension

*   **Purpose:** Offers convenience methods for applying predefined ADC colors to different parts of an ADC model, handling both Physically Based Rendering (PBR) and Shader Graph materials.
*   **Key Features:**
    *   `applyADCColor(_:)`: Applies a standard ADC color (from the `Color.adc` array) to the base color of a Shader Graph material. This is intended for the antibody and linker parts of the ADC.
    *   `applyPayloadColor(_:isInner:)`: Applies colors to the payload entities.  If `isInner` is true, it applies an emissive color (from `Color.adcEmissive`) to a PBR material. If `isInner` is false, it applies a standard ADC color to the "glowColor" parameter of a Shader Graph material (for the outer sphere).

This utility file encapsulates the logic for applying colors to different parts of the ADC model, making it easier to manage and update the visual appearance of the ADC based on user selections or application state. It handles the differences between PBR and Shader Graph materials internally. 