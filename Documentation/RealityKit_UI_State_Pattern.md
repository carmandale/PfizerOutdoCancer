# RealityKit UI State Management Pattern

This document outlines the correct pattern for managing UI state updates in RealityKit, based on Apple's reference implementation in the Spaceship game and our working implementation.

## Core Pattern Overview

The pattern consists of three main parts:
1. Observable Parameters as Source of Truth
2. Component State Management
3. UI-Entity Connection Maintenance

## Reference Implementation (Spaceship Game)

### 1. Parameter Definition
```swift
// In AppModel.swift
@Observable
final class AppModel {
    var shipControlParameters = ShipControlParameters()
}

// In ShipControl.swift
@Observable
class ShipControlParameters {
    var throttle: Float = 0
    var pitch: Float = 0
    var roll: Float = 0
}
```

### 2. Component Setup
```swift
// In FlightSchoolView.swift
spaceship.components.set(ShipControlComponent(parameters: .init()))
spaceship.components.set(
    ClosureComponent { _ in
        if let localThrottle = spaceship.components[ThrottleComponent.self] {
            throttle = localThrottle.throttle
        }
    }
)
```

### 3. State Updates
```swift
// In ShipControlSystem.swift
func update(context: SceneUpdateContext) {
    for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
        guard let shipControlComponent = entity.components[ShipControlComponent.self] else { return }
        let parameters = shipControlComponent.parameters
        entity.components.set([
            ThrottleComponent(throttle: parameters.throttle),
            PitchRollComponent(pitch: parameters.pitch, roll: parameters.roll)
        ])
    }
}
```

## Our Implementation Pattern

### 1. Parameter Management
```swift
// In AttackCancerViewModel.swift
@Observable
final class AttackCancerViewModel {
    var cellParameters: [CancerCellParameters] = []
}

@Observable
public class CancerCellParameters {
    public var cellID: Int? = nil
    public var hitCount: Int = 0
    public var requiredHits: Int
    // ... other properties
}
```

### 2. Entity-UI Connection
From our working backup implementation:
```swift
// Entity Creation with ID
cell.name = "cancer_cell_\(index)"

// UI Attachment with matching ID
Attachment(id: "\(i)") {
    HitCounterView(
        hits: Binding(
            get: {
                appModel.gameState.cancerCells
                    .first(where: { cell in
                        cell.components[CancerCellComponent.self]?.cellID == i
                    })?
                    .components[CancerCellComponent.self]?
                    .hitCount ?? 0
            },
            set: { _ in }
        )
    )
}

// UI Attachment Component
let uiAttachment = UIAttachmentComponent(attachmentID: i)
meter.components[UIAttachmentComponent.self] = uiAttachment
```

### 3. Component and Parameter Connection
```swift
// In spawn function
func spawnSingleCancerCell(in root: Entity, from template: Entity, index: Int) {
    let cell = template.clone(recursive: true)
    cell.name = "cancer_cell_\(index)"
    
    // Ensure parameters have matching ID
    cellParameters[index].cellID = index
    
    // Set state component with parameters reference
    cell.components.set(CancerCellStateComponent(parameters: cellParameters[index]))
    
    // Add ClosureComponent for UI updates
    cell.components.set(ClosureComponent { _ in
        if let stateComponent = cell.components[CancerCellStateComponent.self] {
            // UI updates happen automatically through @Observable parameters
        }
    })
}
```

## State Update Patterns

### 1. Parameter Creation
```swift
// Create parameters on-demand during spawning, NOT pre-initialized
func spawnSingleCancerCell(in root: Entity, from template: Entity, index: Int) {
    let parameters = CancerCellParameters(cellID: index)
    cellParameters.append(parameters)
    // ... rest of spawning logic
}
```

### 2. Collision and Movement Updates
```swift
// Handle collisions through game state
subscription = content.subscribe(to: CollisionEvents.Began.self) { [weak appModel] event in
    appModel?.gameState.handleCollisionBegan(event)
}

// Use ClosureComponent for frame-by-frame updates
cell.components.set(
    ClosureComponent { _ in
        if let stateComponent = cell.components[CancerCellStateComponent.self] {
            // Update parameters from state
            parameters.hitCount = stateComponent.hitCount
        }
    }
)

// Separate movement system for ADC
class ADCMovementSystem: System {
    // Handles ADC movement independently
    func update(context: SceneUpdateContext) {
        // Update ADC positions and states
    }
}
```

### 3. UI Attachment Pattern
```swift
// Set up UI attachments AFTER all cells are spawned
for i in 0..<maxCancerCells {
    if let meter = attachments.entity(for: "\(i)"),
       root.findEntity(named: "cancer_cell_\(i)") != nil {
        root.addChild(meter)
        
        // Add UIAttachmentComponent to the UI entity
        let uiAttachment = UIAttachmentComponent(attachmentID: i)
        meter.components[UIAttachmentComponent.self] = uiAttachment
        
        // Add BillboardComponent for camera facing
        meter.components.set(BillboardComponent())
    }
}
```

## Key Points to Remember

1. **Parameter Management**
   - Keep parameters as observable objects
   - Maintain cellID for proper entity-UI connection
   - Parameters array in ViewModel is source of truth

2. **Entity-UI Connection**
   - Use consistent IDs across entity names and UI attachments
   - Maintain UIAttachmentComponent for connection
   - Use findEntity with matching names for verification

3. **State Updates**
   - Update parameters directly through component reference
   - Let @Observable handle UI updates
   - Use ClosureComponent for any additional UI sync needs

4. **Component Structure**
   - State component holds reference to parameters
   - Marker component (if needed) for entity identification
   - System manages component updates

## Key Implementation Notes

1. **Parameter Management**
   - Create parameters on-demand during spawning
   - Do NOT pre-initialize parameter array
   - Maintain cellID for proper entity-UI connection

2. **State Updates**
   - Use ClosureComponent for frame-by-frame updates
   - Handle collisions through game state
   - Keep movement system separate from state updates

3. **UI Updates**
   - Set up UI attachments after all cells are spawned
   - Use consistent IDs across entity names and UI attachments
   - Let @Observable handle UI updates through parameter changes

## Common Pitfalls to Avoid

1. Don't create new parameter instances when updating state
2. Don't lose the ID connection between entities and UI
3. Don't try to maintain separate state copies
4. Don't skip the UIAttachmentComponent setup

## Reference Project Examples

The Spaceship game project demonstrates this pattern in:
- `/REFERENCE_PROJECTS/CreatingASpaceshipGame/Spaceship/Views/FlightSchoolView.swift`
- `/REFERENCE_PROJECTS/CreatingASpaceshipGame/Spaceship/ECS/SpaceshipControl/ShipControl.swift`
- `/REFERENCE_PROJECTS/CreatingASpaceshipGame/Spaceship/AppModel.swift`

Our working backup implementation:
- `/SpawnAndAttrack/Views/AttackCancerView.backup.swift`

# State Update Pattern for RealityKit Components

## Component State Flow
1. RealityKit Component (Source of Truth)
```swift
// State lives in component
struct CancerCellStateComponent: Component {
    let parameters: CancerCellParameters
}
```

2. Observable Parameters (UI State)
```swift
@Observable 
class CancerCellParameters {
    var hitCount: Int
    var isDestroyed: Bool
    // ... other state
}
```

3. ClosureComponent (Sync Bridge)
```swift
cell.components.set(
    ClosureComponent { [weak self] _ in
        guard let stateComponent = cell.components[CancerCellStateComponent.self],
              let cellID = stateComponent.parameters.cellID else { return }
        
        // Sync state to parameters
        let parameters = self.cellParameters[cellID]
        parameters.hitCount = stateComponent.parameters.hitCount
        parameters.isDestroyed = stateComponent.parameters.isDestroyed
    }
)
```

## Key Principles

1. **Single Source of Truth**
   - RealityKit Component holds the authoritative state
   - Never update @Observable parameters directly
   - Always update through component then let ClosureComponent sync

2. **State Updates**
   - Update component first:
   ```swift
   var stateComponent = entity.components[CancerCellStateComponent.self]
   stateComponent.parameters.hitCount += 1
   entity.components[CancerCellStateComponent.self] = stateComponent
   ```
   - ClosureComponent syncs to @Observable
   - UI updates automatically through bindings

3. **Lifecycle Management**
   - Clear state when entity is destroyed
   - Remove UI elements when no longer needed
   - Handle destroyed state in view bindings

## UI Attachment Pattern with Observable State

When creating UI attachments that need to observe RealityKit component state, use this pattern:

```swift
// In RealityView attachments
ForEach(0..<maxCells, id: \.self) { i in
    Attachment(id: "\(i)") {
        if i < cellParameters.count {
            // Store reference to ensure proper observation
            let parameters = cellParameters[i]
            
            MyView(
                value1: parameters.value1,
                value2: parameters.value2
            )
            .onChange(of: parameters.value1) { _, newValue in
                // Handle changes
            }
        }
    }
}
```

### Key Points:
1. Store local reference to parameters object
2. Pass individual properties to view
3. Observe changes with onChange
4. Avoid accessing array elements directly in view properties

### Common Pitfalls:
```swift
// ❌ Wrong: Direct array access in view properties
MyView(
    value: cellParameters[i].value  // May miss updates
)

// ✅ Correct: Use local reference
let parameters = cellParameters[i]
MyView(
    value: parameters.value  // Properly observes changes
)
```

This pattern ensures:
- Proper observation of @Observable changes
- Reliable UI updates when RealityKit state changes
- Clean view cleanup when entities are destroyed
