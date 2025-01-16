/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The component for following the device.
*/

import RealityKit
import SwiftUI
import ARKit

/// A component to add to any entity that you want to move with the device's transform.
public struct PositioningComponent: Component, Codable {
    var offsetX: Float
    var offsetY: Float
    var offsetZ: Float
    
    public init(offsetX: Float = 0.0, offsetY: Float = 0.0, offsetZ: Float = 0.0) {
        self.offsetX = offsetX
        self.offsetY = offsetY
        self.offsetZ = offsetZ
    }
}
