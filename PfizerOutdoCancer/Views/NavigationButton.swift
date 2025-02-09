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
    var scaleEffect: CGFloat = AppModel.UIConstants.buttonExpandScale
    var theme: GradientTheme?
    var gradientWidth: CGFloat?
    var gradientHeight: CGFloat?
    @State private var rotation: CGFloat = 0.0

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            if let theme = theme, let gradientWidth = gradientWidth, let gradientHeight = gradientHeight {
                // Outer gradient border with soft edge
                Capsule()
                    .frame(width: gradientWidth, height: gradientHeight)
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: theme.colors), 
                        startPoint: .top, endPoint: .bottom))
                    .rotationEffect(.degrees(rotation))
                    .mask {
                        Capsule()
                            .stroke(lineWidth: 20)
                            .frame(width: width ?? 200, height: 60)
                            .blur(radius: 10)
                    }
                
                // Inner gradient border (sharp)
                Capsule()
                    .frame(width: gradientWidth, height: gradientHeight)
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: theme.colors), 
                        startPoint: .top, endPoint: .bottom))
                    .rotationEffect(.degrees(rotation))
                    .mask {
                        Capsule()
                            .stroke(lineWidth: 10)
                            .frame(width: width ?? 200, height: 60)
                    }
            }
            
            configuration.label
                .font(font)
                .padding(.horizontal, AppModel.UIConstants.buttonPaddingHorizontal)
                .padding(.vertical, AppModel.UIConstants.buttonPaddingVertical)
                .frame(width: width)
                .background {
                    RoundedRectangle(cornerRadius: AppModel.UIConstants.buttonCornerRadius, style: .continuous)
                        .fill(.thinMaterial)
                }
                .glassBackgroundEffect()
        }
        .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        .hoverEffect { effect, isActive, proxy in
            effect
                .animation(.easeInOut(duration: AppModel.UIConstants.buttonHoverDuration)) {
                    $0.scaleEffect(isActive ? scaleEffect : 1.0)
                }
        }
        .hoverEffectGroup()
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

struct NavigationButton: View {
    @Environment(AppModel.self) private var appModel
    let title: String
    let action: () async -> Void
    var font: Font = .body
    var scaleEffect: CGFloat = AppModel.UIConstants.buttonExpandScale
    var width: CGFloat? = nil
    var theme: GradientTheme? = nil
    var gradientWidth: CGFloat? = nil
    var gradientHeight: CGFloat? = nil
    
    var body: some View {
        Button {
            Task {
                // Add a small delay to let the press animation complete
                try? await Task.sleep(for: .milliseconds(150))
                await action()
            }
        } label: {
            Text(title)
        }
        .buttonStyle(VisionNavigationButtonStyle(
            font: font,
            width: width,
            scaleEffect: scaleEffect,
            theme: theme,
            gradientWidth: gradientWidth,
            gradientHeight: gradientHeight
        ))
    }
}

struct ScalableButtonStyle: ButtonStyle {
    var scaleFactor: CGFloat = AppModel.UIConstants.buttonExpandScale

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleFactor : 1.0)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

struct ScalableGlassButtonStyle: ButtonStyle {
    var scaleFactor: CGFloat = AppModel.UIConstants.buttonExpandScale
    var cornerRadius: CGFloat = AppModel.UIConstants.buttonCornerRadius

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, AppModel.UIConstants.buttonPaddingHorizontal)
            .padding(.vertical, AppModel.UIConstants.buttonPaddingVertical)
            .background(
                Color.clear
                    .glassBackgroundEffect()
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? scaleFactor : 1.0)
            .animation(.spring(response: AppModel.UIConstants.buttonPressDuration, dampingFraction: 0.5), value: configuration.isPressed)
    }
}
