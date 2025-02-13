//
//  ProgressiveImmersionStyle.swift
//  PfizerOutdoCancer
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

/// A basic implementation of an immersive style for progressive transitions.
/// This struct wraps a Double value (the current immersion level) and a
/// range (the allowed range for progressive transitions) and conforms to `ImmersionStyle`
/// and `Animatable` so SwiftUI can animate changes to its value.
/// 
/// “Progressive” means that the style can interpolate between values (e.g. from 0.65 to 1.0)
/// whereas a “full” style would be a constant 1.
struct ProgressiveImmersionStyle: ImmersionStyle, Animatable {
    // The allowed range for the immersion level.
    let range: ClosedRange<Double>
    // The current immersion level (e.g. 0.65 ... 1.0).
    var value: Double

    // Expose the current value as animatable.
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    // Required by ImmersionStyle.
    func _configureInitialClientSettings(_ initialClientSettings: AnyObject) {
        // No extra configuration needed.
    }

    /// Factory method to create a progressive immersive style.
    /// - Parameters:
    ///   - range: The allowed range for the immersive level.
    ///   - initialAmount: The starting amount within that range.
    /// - Returns: A progressive immersive style value.
    static func progressive(range: ClosedRange<Double>, initialAmount: Double) -> ProgressiveImmersionStyle {
        ProgressiveImmersionStyle(range: range, value: initialAmount)
    }

    // Override the static properties required by ImmersionStyle.
    static var progressive: ProgressiveImmersionStyle {
         ProgressiveImmersionStyle(range: 0.65...1.0, value: 0.65)
    }
    
    static var full: ProgressiveImmersionStyle {
         ProgressiveImmersionStyle(range: 0.65...1.0, value: 1.0)
    }
    
    static var mixed: ProgressiveImmersionStyle {
         ProgressiveImmersionStyle(range: 0.65...1.0, value: 0.65)
    }
} 
