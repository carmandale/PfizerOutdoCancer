I'll help analyze the cleanup and reset requirements. Let me first review the code and create a comprehensive list of properties that need to be reset for a second viewing.

Looking at the code and the issues you described, here's a categorized list of properties that need proper reset:

### Entity State Properties
1. `mainViewEntity` position and rotation
2. `antibodyEntity` opacity and isEnabled
3. `linkerEntity` opacity and isEnabled
4. `payloadEntity` opacity and isEnabled
5. `antibodyRootEntity` isEnabled and components (gestures)
6. `adcLinkers` array elements' isEnabled states
7. `adcPayloadsInner` array elements' isEnabled states
8. `adcPayloadsOuter` array elements' isEnabled states

### View Attachment Properties
1. `adcAttachmentEntity` isEnabled
2. `linkerAttachmentEntity` isEnabled
3. `payloadAttachmentEntity` isEnabled

### Material States
1. Original materials for antibody
2. Original materials for linkers
3. Original materials for payloads (inner and outer)

### Animation/Position States
1. Main view position and rotation
2. ADC complex position and rotation
3. Continuous rotation states

### Data Model States (in ADCDataModel)
Current cleanup includes:
1. `selectedADCAntibody`
2. `selectedADCLinker`
3. `selectedADCPayload`
4. `selectedLinkerType`
5. `selectedPayloadType`
6. `linkersWorkingIndex`
7. `payloadsWorkingIndex`
8. `adcBuildStep`
9. `placedLinkerCount`
10. `placedPayloadCount`
11. Various flags (isVOPlaying, hasInitialVOCompleted, etc.)
12. Step states array
13. Positioning states

### Potential Missing Reset Points
1. Entity transform states
2. Component states (like gesture components)
3. Audio controller states
4. Sort group states
5. Material states for all entities
6. Animation states (any ongoing animations)

Would you like me to:
1. Analyze where and when the cleanup is currently being called?
2. Check if there are any conditions where cleanup might be skipped?
3. Propose specific additions to the cleanup function?

Please let me know which direction you'd like to explore first, and I'll help investigate further.
