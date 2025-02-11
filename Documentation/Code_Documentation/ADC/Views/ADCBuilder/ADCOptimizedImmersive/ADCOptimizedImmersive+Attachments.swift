# ADCOptimizedImmersive+Attachments Documentation

This file is an extension of the `ADCOptimizedImmersive` struct, focusing on the management and positioning of UI attachments within the immersive space.

## `ADCOptimizedImmersive` Extension (Attachments)

*   **Purpose:** Handles the setup, positioning, and updating of SwiftUI view attachments within the immersive scene. This includes the main ADC builder view and attachment entities for linkers and payloads.
*   **Key Features:**
    *   **Attachment Positioning Functions:**
        *   `calculateTargetLinkerPosition()`: Calculates the target position for the linker attachment entity, placing it to the right of the antibody.
        *   `calculateTargetPayloadsPosition()`: Calculates the target position for the payload attachment entity.
        *   `setLinkerAttachmentPosition()`: Sets the position of the linker attachment entity relative to the linker entity.
    *   **Attachment Update Function:**
        *   `updateADC()`: Manages the visibility and positioning of the main view entity and attachment entities based on the current `adcBuildStep` in the `ADCDataModel`.  It controls which attachments are added or removed from the scene.
    *   **Attachment Setup Function:**
        *   `setupAttachments(attachments:)`:  Adds the main ADC builder view (`ADCBuilderView`) as an attachment to the `mainViewEntity`.

This extension encapsulates the logic for managing the UI elements that are presented as attachments within the immersive space, ensuring they are correctly positioned and displayed based on the application's state. The use of attachment entities allows for precise control over the placement and behavior of these UI elements in 3D space. 