# ADCCheckmarkButton Documentation

This file defines the `ADCCheckmarkButton` view, a custom button that displays a checkmark within a circle, used to indicate completion or confirmation.

## `ADCCheckmarkButton`

*   **Purpose:** Provides a reusable button with a checkmark icon that visually indicates whether an action is enabled or completed.
*   **Key Features:**
    *   **Properties:**
        *   `action`: A closure to be executed when the button is tapped.
        *   `isEnabled`: A Boolean value that determines the button's appearance and interaction state.
    *   **State Variable:**
        *   `pulseScale`: A `@State` variable that controls a pulsing scale effect when the button is enabled.
    *   **Layout:** Uses a `ZStack` to overlay the checkmark on top of a circle.
    *   **Circle:** Displays a circle that changes appearance based on `isEnabled`. When enabled, the circle is filled green; otherwise, it's a white outline with reduced opacity.
    *   **Checkmark:** Displays a checkmark icon that is visible when `isEnabled` is true. The checkmark has a pulsing scale animation when enabled.
    *   **Animation:** Uses `animation` to smoothly transition between the enabled and disabled states.
    *   **`onAppear` and `onChange`:**  These modifiers manage the pulsing animation, starting it when the button becomes enabled and resetting the scale when it becomes disabled.
    *   **`startPulsing()`:** A private helper function to start the pulsing animation.

This custom button provides a clear visual indication of whether an action is available or has been completed, with a subtle pulsing animation to draw attention to the enabled state. 