# ADC Placer Gesture System PRD

## Overview
This document outlines the requirements for adding basic gesture interaction to a placed ADC in the Lab environment during second visits (when `appModel.hasBuiltADC` is true).

## Background
When a user has previously built an ADC (indicated by `appModel.hasBuiltADC`), we want to display their configured ADC template at the "ADC_placer" location in the lab environment and allow basic gesture interactions.

## Current Implementation
- ADC template is configured in `AppModel.preloadAssets()` during phase transition
- Template is stored in `gameState.adcTemplate`
- Template is cloned and used in `AttackCancerInstructionsView.swift`
- Lab environment is managed by `LabViewModel.swift`

## Requirements

### 1. Template Access in Lab Environment
```swift
extension LabViewModel {
    // Store ADC template reference
    var adcTemplate: Entity?
    
    // Setup method for second visits
    func setupADCPlacer(in root: Entity) {
        // Only proceed if we have a built ADC
        guard appModel.hasBuiltADC,
              let placerEntity = root.findEntity(named: "ADC_placer"),
              let template = adcTemplate else {
            return
        }
        
        // Clone and place template
        let adc = template.clone(recursive: true)
        
        // Add input target and gesture components
        adc.components.set(InputTargetComponent())
        adc.components.set(ADCGestureComponent(
            canDrag: true,
            pivotOnDrag: false,
            canScale: false,
            canRotate: true
        ))
        
        // Add to scene at placer location
        placerEntity.addChild(adc)
    }
}
```

### 2. Integration Points
1. AppModel:
   ```swift
   // During lab transition
   labState.adcTemplate = gameState.adcTemplate
   ```

2. LabView:
   ```swift
   RealityView { content, attachments in
       let root = appModel.labState.setupRoot()
       content.add(root)
       
       Task { @MainActor in
           await appModel.labState.setupADCPlacer(in: root)
       }
   }
   .installGestures()
   ```

### 3. Cleanup
No additional cleanup needed - existing LabViewModel cleanup will handle template removal:
```swift
func cleanup() {
    if let root = mainEntity {
        root.removeFromParent()  // This removes ADC_placer and its children
    }
    mainEntity = nil
    // ... existing cleanup
}
```

## Success Criteria
1. ADC appears at ADC_placer location on second visits
2. Users can drag and rotate the ADC
3. ADC maintains all color configurations from builder
4. Performance remains smooth during interactions

## Testing Requirements
1. Verify ADC template color preservation
2. Test basic gesture responsiveness
3. Test cleanup during transitions

## Timeline
1. Implementation (1 day):
   - Template integration
   - Basic gesture setup

2. Testing (1 day):
   - Functionality verification
   - Bug fixes

## Dependencies
1. Existing ADC Builder systems
2. RealityKit gesture framework

## Risks and Mitigations
1. Risk: Template state preservation
   - Mitigation: Using proven clone(recursive: true) pattern

2. Risk: Gesture conflicts
   - Mitigation: Using standard InputTargetComponent and ADCGestureComponent setup 