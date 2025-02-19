# ADC Builder Step Navigation PRD

## Overview
This PRD focuses on ensuring reliable step completion tracking and safe chevron navigation in the ADC Builder experience. The goal is to prevent users from advancing steps before proper completion while allowing revisiting of completed steps for color changes.

## Current Implementation Analysis

### Files Involved
- `ADCDataModel.swift`: Core state management
- `ADCBuilderView.swift`: Main UI and navigation controls
- `ADCSelectorView.swift`: Antibody selection
- `ADCLinkerSelectorView.swift`: Linker selection
- `ADCPayloadSelectorView.swift`: Payload selection

### Current State Management
```swift
// In ADCDataModel
var adcBuildStep = 0
var isCurrentStepComplete: Bool {
    switch adcBuildStep {
    case 0:  // Antibody
        return selectedADCAntibody != nil
    case 1:  // Linker
        return selectedLinkerType != nil && linkersWorkingIndex == 3
    case 2:  // Payload
        return selectedPayloadType != nil && payloadsWorkingIndex == 3
    default:
        return true
    }
}

// Voice over and transition state
var isVOPlaying = false
var hasInitialVOCompleted = false
var antibodyVOCompleted = false
var antibodyStepCompleted = false
var manualStepTransition: Bool = false
```

## Issues to Address

### 1. Step Completion Validation
Current implementation has several gaps:
- `isCurrentStepComplete` only checks selection, not checkmark confirmation
- Forward navigation possible before proper step completion
- Unclear distinction between "selected" and "confirmed" states
- Inconsistent handling between initial completion and revisits

### 2. Chevron Navigation Issues
- Forward chevron enabled state needs tighter coupling with step completion
- Back navigation needs to preserve completion state
- Manual transitions need clearer rules
- Voice over interruption during navigation needs prevention

### 3. State Management Complexity
- Multiple boolean flags tracking similar states
- Unclear relationships between VO completion and step completion
- Navigation state spread across multiple properties

## Proposed Solution

### 1. Step State Management
```swift
// In ADCDataModel
struct StepState {
    var colorSelected: Bool
    var checkmarkClicked: Bool
}

var stepStates: [StepState] = [
    StepState(), // Antibody
    StepState(), // Linker
    StepState(), // Payload
]

var isCurrentStepComplete: Bool {
    guard adcBuildStep < stepStates.count else { return true }
    let state = stepStates[adcBuildStep]
    
    switch adcBuildStep {
    case 0:  // Antibody
        return selectedADCAntibody != nil && state.checkmarkClicked
    case 1:  // Linker
        return selectedLinkerType != nil && 
               linkersWorkingIndex == 3 && 
               state.checkmarkClicked
    case 2:  // Payload
        return selectedPayloadType != nil && 
               payloadsWorkingIndex == 3 && 
               state.checkmarkClicked
    default:
        return true
    }
}

var canMoveForward: Bool {
    if isVOPlaying { return false }
    return isCurrentStepComplete || stepStates[adcBuildStep].checkmarkClicked
}

var canMoveBack: Bool {
    return adcBuildStep > 0 && !isVOPlaying
}
```

### 2. Navigation Control Updates
```swift
// In ADCBuilderView
// Forward Chevron
Button(action: {
    withAnimation {
        if stepStates[adcBuildStep].checkmarkClicked {
            // Previously completed step - skip VO
            manualStepTransition = true
        }
        adcBuildStep += 1
    }
}) {
    Image(systemName: "chevron.right")
}
.opacity(canMoveForward ? 1.0 : 0.1)
.disabled(!canMoveForward)

// Back Chevron
Button(action: {
    withAnimation {
        manualStepTransition = true
        adcBuildStep -= 1
    }
}) {
    Image(systemName: "chevron.left")
}
.opacity(canMoveBack ? 1.0 : 0.1)
.disabled(!canMoveBack)
```

## Implementation Plan

### Phase 1: State Management Updates
1. Add `StepState` struct to `ADCDataModel`
2. Add `stepStates` array
3. Update `isCurrentStepComplete` implementation
4. Add `canMoveForward` and `canMoveBack` computed properties

### Phase 2: Navigation Control Updates
1. Update forward chevron in `ADCBuilderView`
2. Update back chevron
3. Modify transition logic for VO handling

### Phase 3: Testing and Validation
1. Test basic step completion
   - Select color
   - Complete placements
   - Click checkmark
   - Verify forward enabled

2. Test navigation
   - Forward progression
   - Back navigation
   - Skip to completion
   - Color changes

3. Test voice over behavior
   - Initial playback
   - Skip on revisits
   - No interruption
   - Proper completion tracking

## Success Criteria

### 1. Step Completion
- [ ] Users cannot advance without:
  - Selecting a color
  - Completing required placements
  - Clicking checkmark
- [ ] Step completion state persists correctly

### 2. Navigation
- [ ] Forward chevron only enabled when appropriate
- [ ] Back chevron works without breaking state
- [ ] Color changes possible on completed steps
- [ ] No unintended step skips

### 3. Voice Overs
- [ ] Play correctly on first completion
- [ ] Skip appropriately on revisits
- [ ] Cannot be interrupted by navigation
- [ ] State tracked correctly

## Testing Checklist

### Basic Flow
1. Complete each step normally
   - Select color
   - Place components
   - Click checkmark
   - Advance

### Edge Cases
1. Try advancing without completion
2. Rapid forward/back clicking
3. VO interruption attempts
4. Multiple color changes
5. Skip attempts

### State Verification
1. Check step completion persistence
2. Verify VO state tracking
3. Validate navigation state
4. Confirm color selection retention

## Future Considerations
1. Consider adding step completion animation
2. Add user feedback for incomplete steps
3. Consider progress persistence
4. Add analytics for step completion

## Timeline
- Phase 1: 1 day
- Phase 2: 1 day
- Phase 3: 1 day
- Testing: 1 day

## Dependencies
- Existing ADCDataModel
- ADCBuilderView
- Voice over system
- Animation system

## Risks and Mitigations
1. Risk: State complexity
   - Mitigation: Clear documentation and testing

2. Risk: VO timing issues
   - Mitigation: Robust state checks

3. Risk: Navigation edge cases
   - Mitigation: Comprehensive testing

4. Risk: User confusion
   - Mitigation: Clear visual feedback 