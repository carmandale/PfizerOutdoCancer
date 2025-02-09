import SwiftUI

struct GradientNavigationButtonStyle: ButtonStyle {
    let theme: GradientTheme
    let width: CGFloat
    let height: CGFloat
    let buttonWidth: CGFloat
    let buttonHeight: CGFloat
    @State private var rotation: CGFloat = 0.0
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // Outer gradient border
            Capsule()
                .frame(width: width, height: height)
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: theme.colors), 
                    startPoint: .top, endPoint: .bottom))
                .rotationEffect(.degrees(rotation))
                .mask {
                    Capsule()
                        .stroke(lineWidth: 20)
                        .frame(width: buttonWidth, height: buttonHeight)
                        .blur(radius: 10)
                }
                .hoverEffect { effect, isActive, proxy in
                    effect
                        .animation(.easeInOut(duration: 0.2)) {
                            $0.scaleEffect(isActive ? AppModel.UIConstants.buttonExpandScale : 1.0)
                        }
                }
            
            // Inner gradient border
            Capsule()
                .frame(width: width, height: height)
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: theme.colors), 
                    startPoint: .top, endPoint: .bottom))
                .rotationEffect(.degrees(rotation))
                .mask {
                    Capsule()
                        .stroke(lineWidth: 10)
                        .frame(width: buttonWidth, height: buttonHeight)
                }
                .hoverEffect { effect, isActive, proxy in
                    effect
                        .animation(.easeInOut(duration: 0.2)) {
                            $0.scaleEffect(isActive ? AppModel.UIConstants.buttonExpandScale : 1.0)
                        }
                }
            
            // Button content
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        }
        .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

extension View {
    func gradientNavigationButtonStyle(theme: GradientTheme, width: CGFloat, height: CGFloat, buttonWidth: CGFloat, buttonHeight: CGFloat = 60) -> some View {
        self.buttonStyle(GradientNavigationButtonStyle(theme: theme, width: width, height: height, buttonWidth: buttonWidth, buttonHeight: buttonHeight))
    }
}
