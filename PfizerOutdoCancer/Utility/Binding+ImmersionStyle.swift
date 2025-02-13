//
//  Binding+ImmersionStyle.swift
//  PfizerOutdoCancer
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

extension Binding where Value: ImmersionStyle {
    func eraseToAnyImmersionStyle() -> Binding<any ImmersionStyle> {
        Binding<any ImmersionStyle>(
            get: { self.wrappedValue as any ImmersionStyle },
            set: { newValue in
                // Attempt to cast newValue to the concrete type.
                if let converted = newValue as? Value {
                    self.wrappedValue = converted
                } else {
                    // Optionally handle the failure to convert.
                    assertionFailure("Failed to convert newValue to expected type \(Value.self)")
                }
            }
        )
    }
} 