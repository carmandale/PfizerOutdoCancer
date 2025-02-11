# ADCLinkerSelectorView Documentation

This file defines the `ADCLinkerSelectorView`, which allows the user to select a linker type for the ADC (Antibody-Drug Conjugate).

## `ADCLinkerSelectorView`

*   **Purpose:** Presents a set of buttons representing different linker types, allowing the user to choose one and see the number of linkers placed.
*   **Key Features:**
    *   **Environment Variables:** Uses `@Environment` to access `AppModel` and `ADCDataModel`.
    *   **Properties:**
        *   `noButton`: A Boolean flag (currently set to `true`) that disables the checkmark button.  This suggests the functionality to automatically fill all linkers is not yet fully implemented.
    *   **Layout:** Uses a `VStack` to arrange the UI elements.
        *   **Header:** Contains a title, a display of the number of placed linkers, and an `ADCCheckmarkButton`.
        *   **Button Row:** Uses an `HStack` to display three `ADCButtonSquareWithOutline` instances, one for each linker type.
    *   **Button Actions:** Each `ADCButtonSquareWithOutline` has an action that sets the `selectedLinkerType` in the `ADCDataModel`.
    *   **Checkmark Button:** The `ADCCheckmarkButton` is intended to allow the user to fill all remaining linker positions with the selected type, but this functionality is currently disabled.
    *   **Glass Background:** Applies a `glassBackgroundEffect` to the entire view.

This view provides the user interface for selecting a linker type and visually represents the selection process. The integration with `ADCDataModel` ensures that the user's choice is reflected in the application's state. 