//
//  NavigationButton.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 1/21/25.
//

import SwiftUI

struct VisionNavigationButtonStyle: ButtonStyle {
    var font: Font = .body
    var width: CGFloat?
    var scaleEffect: CGFloat = 1.2
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(width: width)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.thinMaterial)
            }
            // Group hover effects together
            .hoverEffect(.highlight)
            .hoverEffect { effect, isActive, proxy in
                effect
                    .animation(.easeInOut(duration: 0.2)) {
                        $0.scaleEffect(isActive ? scaleEffect : 1.0)
                    }
            }
            .hoverEffectGroup()
            // Add press animation
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct NavigationButton: View {
    let title: String
    let action: () async -> Void
    var font: Font = .body
    var scaleEffect: CGFloat = 1.2
    var width: CGFloat? = nil
    
    var body: some View {
        Button {
            Task { await action() }
        } label: {
            Text(title)
        }
        .buttonStyle(VisionNavigationButtonStyle(
            font: font,
            width: width,
            scaleEffect: scaleEffect
        ))
    }
}

// Keep these for backward compatibility if needed
struct ScalableButtonStyle: ButtonStyle {
    var scaleFactor: CGFloat = 1.2

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleFactor : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

struct ScalableGlassButtonStyle: ButtonStyle {
    var scaleFactor: CGFloat = 1.2
    var cornerRadius: CGFloat = 16

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Color.clear
                    .glassBackgroundEffect()
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? scaleFactor : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: configuration.isPressed)
    }
}
