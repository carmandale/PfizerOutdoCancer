import Foundation
import RealityKit
import SwiftUI

// MARK: - Rotate -

/// Gesture extension to support rotation gestures.
public extension Gesture where Value == EntityTargetValue<RotateGesture3D.Value> {
    
    /// Connects the gesture input to the `GestureComponent` code.
    func useADCGestureComponent() -> some Gesture {
        onChanged { value in
            guard var gestureComponent = value.entity.adcGestureComponent else { return }
            
            gestureComponent.onChanged(value: value)
            
            value.entity.components.set(gestureComponent)
        }
        .onEnded { value in
            guard var gestureComponent = value.entity.adcGestureComponent else { return }
            
            gestureComponent.onEnded(value: value)
            
            value.entity.components.set(gestureComponent)
        }
    }
}

// MARK: - Drag -

/// Gesture extension to support drag gestures.
public extension Gesture where Value == EntityTargetValue<DragGesture.Value> {
    
    /// Connects the gesture input to the `GestureComponent` code.
    func useADCGestureComponent() -> some Gesture {
        onChanged { value in
            guard var gestureComponent = value.entity.adcGestureComponent else { return }
            
            gestureComponent.onChanged(value: value)
            
            value.entity.components.set(gestureComponent)
        }
        .onEnded { value in
            guard var gestureComponent = value.entity.adcGestureComponent else { return }
            
            gestureComponent.onEnded(value: value)
            
            value.entity.components.set(gestureComponent)
        }
    }
}

// MARK: - Magnify (Scale) -

/// Gesture extension to support scale gestures.
public extension Gesture where Value == EntityTargetValue<MagnifyGesture.Value> {
    
    /// Connects the gesture input to the `GestureComponent` code.
    func useADCGestureComponent() -> some Gesture {
        onChanged { value in
            guard var gestureComponent = value.entity.adcGestureComponent else { return }
            
            gestureComponent.onChanged(value: value)
            
            value.entity.components.set(gestureComponent)
        }
        .onEnded { value in
            guard var gestureComponent = value.entity.adcGestureComponent else { return }
            
            gestureComponent.onEnded(value: value)
            
            value.entity.components.set(gestureComponent)
        }
    }
}
