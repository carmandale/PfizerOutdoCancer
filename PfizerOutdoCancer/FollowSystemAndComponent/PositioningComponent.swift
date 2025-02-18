/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
The component for following the device.
*/

import Foundation
import RealityKit
import SwiftUI
import ARKit

/// A component to add to any entity that you want to move with the device's transform.
public struct PositioningComponent: Component, Codable {
    var offsetX: Float
    var offsetY: Float
    var offsetZ: Float
    var needsPositioning: Bool
    var shouldAnimate: Bool
    var animationDuration: TimeInterval
    var isAnimating: Bool
    
    public init(
        offsetX: Float = 0.0,
        offsetY: Float = 0.0,
        offsetZ: Float = 0.0,
        needsPositioning: Bool = true,
        shouldAnimate: Bool = false,
        animationDuration: TimeInterval = 0.5,
        isAnimating: Bool = false
    ) {
        self.offsetX = offsetX
        self.offsetY = offsetY
        self.offsetZ = offsetZ
        self.needsPositioning = needsPositioning
        self.shouldAnimate = shouldAnimate
        self.animationDuration = animationDuration
        self.isAnimating = isAnimating
    }
}
