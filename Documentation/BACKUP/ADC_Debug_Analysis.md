# ADC System Debug Analysis

## Current Issues
1. ADCs are not causing cell death
2. ADCs are repeatedly targeting the same attachment points
3. Untargeted ADCs are not flying forward before seeking targets

## System Components Analysis

### 1. ADC Movement System
- Located in: `ADCMovementSystem.swift`
- Current State:
  - Only handles `.moving` state in update loop
  - `.seeking` state exists in `ADCComponent` but not handled
  - Movement uses Bezier curves with configurable arc heights
  - Has retargeting capability but may not be properly maintaining occupied states

### 2. Target Finding System
- Located in: `ADCMovementSystem+Retargeting.swift`
- Current State:
  - Has occupation checks but logs show repeated targeting
  - Uses distance-based selection
  - Validates cell state and availability
  - May not be properly maintaining `isOccupied` state on attachment points

### 3. Cell Death System
- Located in: `CancerCellComponent.swift`
- Current State:
  - Uses `CancerCellParameters` for state tracking
  - Has hit count and required hits logic
  - Death trigger exists but may not be executing
  - Needs investigation of collision -> hit registration -> death chain

## Questions Requiring Investigation

### Movement System
1. How is the seeking state supposed to integrate with existing movement?
2. What's the expected duration of seeking before target acquisition?
3. Is the movement system properly handling state transitions?

### Target Selection
1. Where and how are attachment points marked as occupied?
2. Are occupied states being properly cleared when ADCs are destroyed?
3. Is there a validation system to prevent multiple ADCs targeting the same point?

### Cell Death Chain
1. Are collisions being properly detected and registered?
2. Is hit registration properly incrementing hit counts?
3. Are death triggers being called when hit threshold is reached?
4. Is the particle/animation system for death properly connected?

## Next Steps for Investigation

1. Need to examine collision handling system thoroughly
2. Need to trace complete hit registration flow
3. Need to verify death trigger system connections
4. Need to understand attachment point occupation lifecycle

## Current Confidence Level: 6/10

### High Confidence Areas (8-9/10)
- Understanding of movement system architecture
- Target finding logic structure
- State management components

### Medium Confidence Areas (5-7/10)
- Collision handling flow
- Seeking behavior integration
- Attachment point occupation management

### Low Confidence Areas (3-4/10)
- Complete death trigger chain
- Physics interaction details
- Particle/animation system integration

## Required Documentation Review
- Need to review collision system documentation
- Need to examine particle system integration
- Need to understand audio/visual feedback systems

## Critical Issues Found

### 1. Collision Component Missing
```swift
// Set up collision component
let shape = ShapeResource.generateSphere(radius: 0.069)
let collision = CollisionComponent(
    shapes: [shape],
    filter: .init(group: .adc, mask: .cancerCell)
)
// adc.components.set(collision)  // <-- COMMENTED OUT
```
ADCs are spawned without collision components, which means they can't trigger collision events.

### 2. Movement System State Handling
```swift
guard var adcComponent = entity.components[ADCComponent.self],
      adcComponent.state == .moving,  // <-- Only handles .moving state
      let start = adcComponent.startWorldPosition,
      let targetID = adcComponent.targetEntityID else { continue }
```
The movement system doesn't handle the `.seeking` state, causing untargeted ADCs to remain stationary.

### 3. Hit Registration Chain
1. Collision Detection:
   - Collision components not added to ADCs
   - Collision filter groups exist but aren't being used
2. Hit Processing:
   - Hit registration code exists and looks correct
   - But never triggered due to missing collision components

### 4. Attachment Point Management
```swift
// In findNewTarget
guard let attachComponent = entity.components[AttachmentPoint.self],
      !attachComponent.isOccupied else {
    continue
}
```
Attachment points are checked for occupation but:
- Occupation state may not be properly cleared when ADCs are destroyed
- Multiple ADCs might target same point before occupation is set

## Required Fixes (Confidence Level: 8/10)

### 1. Collision System (High Confidence)
- Uncomment collision component addition in ADC spawning
- Verify collision group/mask setup
- Add logging to verify collision events

### 2. Movement System (High Confidence)
- Add seeking state handling to movement system
- Implement minimum seeking duration
- Add smooth transition to targeting

### 3. Attachment Point Management (Medium Confidence)
- Add occupation state clearing when ADCs are destroyed
- Add validation to prevent multiple ADCs targeting same point
- Add logging for attachment point state changes

### 4. Death System Integration (Medium Confidence)
- Verify hit count incrementation
- Add logging throughout death trigger chain
- Verify particle/animation system connections

## Questions Requiring Clarification

1. Movement Behavior
- What's the desired minimum seeking duration?
- Should seeking ADCs use the same arc-based movement?
- What's the preferred seeking speed?

2. Targeting Behavior
- Should ADCs prefer closer or more damaged cells?
- How should we handle multiple ADCs seeking at once?
- What's the maximum seeking range?

3. Physics Integration
- Should seeking ADCs have different physics properties?
- How should we handle collisions during seeking?

## Next Steps

1. Immediate Fixes (High Confidence)
- Re-enable collision components
- Implement seeking state in movement system
- Add attachment point state management

2. Verification Steps
- Add comprehensive logging
- Test each system independently
- Verify full interaction chain

3. Required Information
- Preferred seeking duration
- Targeting priorities
- Physics behavior preferences

## Current Confidence Level: 8/10

The core issues are now clear and the fixes are straightforward. The main uncertainties are around specific behavior preferences rather than technical implementation. 