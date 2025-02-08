import SwiftUI

// Custom hover effects will be implemented following Apple's patterns 

/// Expands and scales content on hover.
//struct ExpandEffect: CustomHoverEffect {
//    func body(content: Content) -> some CustomHoverEffect {
//        content.hoverEffect { effect, isActive, proxy in
//            effect.animation(.linear.delay(isActive ? 0.8 : 0.2)) {
//                $0.clipShape(
//                    .capsule.size(
//                        width: isActive ? proxy.size.width : proxy.size.height,
//                        height: proxy.size.height,
//                        anchor: .leading
//                    )
//                )
//                .scaleEffect(
//                    isActive ? 1.05 : 1.0,
//                    anchor: UnitPoint(x: (proxy.size.height / 2) / proxy.size.width, y: 0.5)
//                )
//            }
//        }
//    }
//}

/// Fades content between the `from` and `to` properties on hover.
struct FadeEffect: CustomHoverEffect {
    var opacityFrom: Double = 0
    var opacityTo: Double = 1

    func body(content: Content) -> some CustomHoverEffect {
        content.hoverEffect { effect, isActive, _ in
            effect.animation(.linear.delay(isActive ? 0.8 : 0.2)) {
                $0.opacity(isActive ? opacityTo : opacityFrom)
            }
        }
    }
}

/// Creates a glowing outline effect that animates on hover
struct GlowingOutlineEffect: CustomHoverEffect {
    func body(content: Content) -> some CustomHoverEffect {
        content.hoverEffect { effect, isActive, proxy in
            effect.animation(.default.delay(isActive ? 0.2 : 0.2)) {
                $0.clipShape(
                    .capsule.size(
                        width: proxy.size.width,
                        height: proxy.size.height,
                        anchor: .leading
                    )
                )
            }
            .animation(.easeInOut(duration: 0.2)) {
                $0.scaleEffect(isActive ? AppModel.UIConstants.buttonExpandScale : 1.0)
            }
        }
    }
}

/// Creates a rainbow gradient border that animates on hover
struct GradientBorderEffect: CustomHoverEffect {
    func body(content: Content) -> some CustomHoverEffect {
        content.hoverEffect { effect, isActive, _ in
            effect.animation(.default.delay(isActive ? 0.2 : 0.2)) {
                $0.opacity(isActive ? 1.0 : 0.3)
            }
        }
    }
}
