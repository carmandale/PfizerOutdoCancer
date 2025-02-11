# ADCBuilderView Documentation

This file defines the `ADCBuilderView`, which is the main view for the ADC (Antibody-Drug Conjugate) building process.

## `ADCBuilderView`

*   **Purpose:** Presents the user interface for building an ADC, including selecting components, displaying instructions, and showing progress.
*   **Key Features:**
    *   **Environment Variables:** Uses `@Environment` to access `AppModel`, `ADCDataModel`, `openWindow`, `dismissWindow`, and `dismissImmersiveSpace`.
    *   **Layout:** Uses a `VStack` to arrange the UI elements vertically.
    *   **Header:** Displays the Pfizer logo and a title that changes based on the current build step (`dataModel.adcBuildStep`).  Includes glowing text effects for emphasis.
    *   **Description:** Shows a description of the current build step.
    *   **Progress Bar:** Displays a `VOProgressBar` when voice-over is playing.
    *   **Selector Views:** Shows different selector views (`ADCSelectorView`, `ADCLinkerSelectorView`, `ADCPayloadSelectorView`) based on the current build step.
    *   **Navigation Button:** Displays a button to proceed to the "Attack Cancer" phase when the ADC is complete.
    *   **Navigation Chevrons:**  Includes back and forward chevrons to manually navigate between build steps.
    *   **Animations:** Uses `transition`, `animation`, and `withAnimation` to create smooth transitions and visual effects.
    *   **Glass Background:** Applies a `glassBackgroundEffect` to the main content area.
    *   **Glowing Modifier:**  A custom `ViewModifier` (`GlowingModifier`) is defined to create a glowing text effect.  This modifier uses a pulsating animation.
    *   **VOProgressBar:** A custom `View` that displays a progress bar for voice-over playback.

This view is the primary interface for the ADC building experience, guiding the user through the steps and providing visual feedback. It heavily relies on the `ADCDataModel` to manage its state and display the appropriate content. 