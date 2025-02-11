# ADCDataModel Documentation

This file defines the `ADCDataModel` class, which manages the data and state related to the ADC (Antibody-Drug Conjugate) building process.

## `ADCDataModel`

*   **Purpose:** Holds the data and state for the ADC building process, including user selections, voice-over progress, and build step management.
*   **Key Features:**
    *   `@Observable`: Uses the `@Observable` macro (from the Observation framework) to make the class observable by SwiftUI views. This means changes to the properties of this class will automatically trigger UI updates.
    *   **Properties:**
        *   `selectedADCAntibody`, `selectedADCLinker`, `selectedADCPayload`: Store the user's color selections for the ADC components.
        *   `selectedLinkerType`, `selectedPayloadType`: Store the user's selection for linker and payload types.
        *   `linkersWorkingIndex`, `payloadsWorkingIndex`: Track the progress of placing linkers and payloads.
        *   `adcBuildStep`: Represents the current step in the ADC building process.
        *   `placedLinkerCount`, `placedPayloadCount`: Keep track of the number of linkers and payloads that have been placed.
        *   `isVOPlaying`, `hasInitialVOCompleted`, `antibodyVOCompleted`, `antibodyStepCompleted`, `showSelector`:  Flags to control UI state and voice-over playback.
        *   `manualStepTransition`: Flag to indicate if the user manually transitioned to the next step.
        *   `voiceOverProgress`: Tracks the progress of the current voice-over.
        *   `voiceOverDurations`: A dictionary that stores the duration of each voice-over clip.
        *   `isCurrentStepComplete`: A computed property that determines if the current build step is complete based on user selections.
    *   **Methods:**
        *   `fillAllLinkers()`, `fillAllPayloads()`:  Methods to automatically fill all linker or payload positions with the currently selected type.
        *   `getADCImageName()`, `getLinkerImageName()`, `getPayloadImageName()`:  Helper methods to get the image names for the selected ADC components.
        *   `cleanup()`: Resets the data model to its initial state.

*   **`ADCUIAttachments` Enum:** Defines string constants for attachment IDs used to attach SwiftUI views to RealityKit entities.

This class is central to the ADC building process, managing the user's choices, the state of the build, and the associated UI logic. The use of `@Observable` makes it easy to bind SwiftUI views to this data and keep the UI in sync with the model. 