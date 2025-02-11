# ADC Color Extensions Documentation

This file provides extensions to `Color` and `UIColor` to define and work with a custom color palette specific to the ADC (Antibody-Drug Conjugate) project.

## `Color` Extension

*   **Purpose:** Adds convenience initializers and static properties for custom ADC colors.
*   **Key Features:**
    *   `init(hex:opacity:)`: Initializes a `Color` from a hexadecimal color code.
    *   Static properties for predefined colors: `adcDarkBlue`, `adcLightBlue`, `adcYellow`, `adcWhite`, `adcDarkBlueEmissive`, `adcLightBlueEmissive`, `adcYellowEmissive`, `adcWhiteEmissive`.
    *   Static arrays for color palettes: `adc` (standard colors), `adcEmissive` (emissive colors).
    *   `toUIColor`: Converts a `Color` to a `UIColor`.

## `UIColor` Extension

*   **Purpose:** Adds convenience initializers and static properties for custom ADC colors, mirroring the `Color` extension.
*   **Key Features:**
    *   `convenience init(hex:opacity:)`: Initializes a `UIColor` from a hexadecimal color code.
    *   Static properties for predefined colors (same names as in the `Color` extension).
    *   Static arrays for color palettes: `adc` (standard colors), `adcEmissive` (emissive colors).
    *   `hex`: Computed property that returns the hexadecimal representation of a `UIColor`.

These extensions provide a centralized and convenient way to manage and use a consistent color scheme throughout the application, making it easier to maintain and update the visual style. 