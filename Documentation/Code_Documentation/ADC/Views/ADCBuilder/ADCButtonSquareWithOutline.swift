# ADCButtonSquareWithOutline Documentation

This file defines the `ADCButtonSquareWithOutline` view, a custom button used in the ADC builder's selector views.

## `ADCButtonSquareWithOutline`

*   **Purpose:** Provides a reusable square button with an image, an optional outline, and a text description. Used for selecting ADC components (antibody, linker, payload).
*   **Key Features:**
    *   **Environment Variables:** Uses `@Environment` to access `AppModel` and `ADCDataModel`.
    *   **Properties:**
        *   `imageName`: The name of the image to display.
        *   `outlineColor`: The color of the outline.
        *   `description`: The text description below the button.
        *   `index`: An integer representing the index of the button (used for selection).
        *   `isSelected`: A closure that returns a Boolean indicating whether the button is currently selected.
        *   `action`: A closure to be executed when the button is tapped.
        *   `buttonSize`: The size of the button.
        *   `cornerRadius`: The corner radius of the button and outline.
    *   **Layout:** Uses a `VStack` to arrange the image and description vertically.
    *   **Button:** Uses a `Button` with a custom label that includes the image and an optional outline.
    *   **Overlay:**  Adds a `RoundedRectangle` overlay to create the outline effect. The outline is only visible when `isSelected()` returns `true`.
    *   **Text:** Displays the `description` text below the button.

This custom button provides a consistent visual style for the selection options in the ADC builder, including visual feedback for the currently selected item. 