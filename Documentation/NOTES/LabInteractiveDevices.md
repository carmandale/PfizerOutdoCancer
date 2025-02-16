# Lab Interactive Devices Implementation Plan

## Overview
Implement interactive laptop and PC monitor devices in the lab that toggle the LibraryView window when tapped, using RealityKit's Entity Component System (ECS) pattern consistent with existing codebase patterns.

## Current State
- Laptop and PC monitor entities exist in lab_environment with auto-numbered instances
- LibraryView window auto-opens when entering lab phase
- Need to make LibraryView window toggle only on device interaction

## Implementation Plan

### 1. Create Interactive Device Component
Similar to TraceComponent pattern:
```swift
struct InteractiveDeviceComponent: Component {
    // Empty marker component, similar to TraceComponent
}
```

### 2. Create Helper for Finding Devices
```swift
private func findInteractiveDevices(in root: Entity) -> [Entity] {
    var results = [Entity]()
    
    // Check root itself
    if root.name.lowercased().contains("laptop") || 
       root.name.lowercased().contains("pcmonitor") {
        results.append(root)
    }
    
    // Search children
    for child in root.children {
        results.append(contentsOf: findInteractiveDevices(in: child))
    }
    
    return results
}
```

### 3. Configure Devices in LabView
In setupEnvironment():
```swift
if let labEnvironment = await appModel.assetLoadingManager.instantiateEntity("lab_environment") {
    mainEntity?.addChild(labEnvironment)
    
    // Find and configure all interactive devices
    let devices = findInteractiveDevices(in: labEnvironment)
    for device in devices {
        device.components[CollisionComponent.self] = CollisionComponent()
        device.components[InputTargetComponent.self] = InputTargetComponent()
        device.components[InteractiveDeviceComponent.self] = InteractiveDeviceComponent()
    }
    
    // Debug logging
    print("🏢 Lab Environment added to MainEntity")
    print("📍 MainEntity position after adding lab: \(String(describing: mainEntity?.position))")
    print("📍 Lab Environment position: \(labEnvironment.position)")
    print("🎯 Found \(devices.count) interactive devices")
}
```

### 4. Update Window Management
1. Remove auto-open from PfizerOutdoCancerApp.swift handleWindowsForPhase()
2. Add initial close in LabView.onAppear (already implemented)
3. Keep existing toggle logic in handleDeviceTap()

### 5. Tap Gesture Handler
```swift
private func makeTapGesture() -> some Gesture {
    SpatialTapGesture()
        .targetedToAnyEntity()
        .onEnded { value in
            guard let tappedEntity = value.entity else { return }
            
            // Check if tapped entity or any parent has InteractiveDeviceComponent
            var currentEntity: Entity? = tappedEntity
            while let entity = currentEntity {
                if entity.components[InteractiveDeviceComponent.self] != nil {
                    handleDeviceTap()
                    break
                }
                currentEntity = entity.parent
            }
        }
}
```

## Testing Plan
1. Verify LibraryView starts closed when entering lab
2. Confirm tapping any laptop instance opens LibraryView
3. Confirm tapping any PC monitor instance opens LibraryView
4. Verify tapping any interactive device closes LibraryView when open
5. Test window state persists correctly during phase transitions
6. Verify all instances of devices are properly marked with component

## Files to Modify
1. Create InteractiveDeviceComponent.swift in Components folder
2. PfizerOutdoCancerApp.swift - remove auto-open
3. LabView.swift - add device finding and configuration

## Next Steps
1. Create component
2. Add recursive device finding
3. Update LabView setup
4. Remove auto-open from app
5. Test implementation

## Notes
- Using component-based approach consistent with TraceComponent pattern
- Recursive search only used during initial setup
- No need for separate system since interaction is simple window toggle
- Follows existing codebase patterns for component usage 