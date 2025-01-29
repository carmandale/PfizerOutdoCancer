import SwiftUI

extension View {
    /// Applies a consistent scale and fade animation for selector views
    /// - Parameter isVisible: Boolean indicating if the selector should be visible
    func selectorAnimation(isVisible: Bool) -> some View {
        modifier(SelectorAnimationModifier(isVisible: isVisible))
    }
}

/// A view modifier that provides consistent scale and fade animations for selector views
private struct SelectorAnimationModifier: ViewModifier {
    let isVisible: Bool
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onChange(of: isVisible) { oldValue, newValue in
                if newValue {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        scale = 1
                        opacity = 1
                    }
                } else {
                    withAnimation(.easeIn(duration: 0.3)) {
                        scale = 0.8
                        opacity = 0
                    }
                }
            }
    }
} 