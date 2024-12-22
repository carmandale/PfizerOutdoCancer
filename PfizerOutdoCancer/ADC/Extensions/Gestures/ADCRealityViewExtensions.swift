import Foundation
import RealityKit
import SwiftUI

// MARK: - RealityView Extensions
public extension RealityView {
    
    /// Apply this to a `RealityView` to pass gestures on to the component code.
    func installGestures() -> some View {
        simultaneousGesture(dragGesture)
            .simultaneousGesture(magnifyGesture)
            .simultaneousGesture(rotateGesture)
    }
    
    /// Builds a drag gesture.
    var dragGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .useADCGestureComponent()
    }
    
    /// Builds a magnify gesture.
    var magnifyGesture: some Gesture {
        MagnifyGesture()
            .targetedToAnyEntity()
            .useADCGestureComponent()
    }
    
    /// Buildsa rotate gesture.
    var rotateGesture: some Gesture {
        RotateGesture3D()
            .targetedToAnyEntity()
            .useADCGestureComponent()
    }
}
