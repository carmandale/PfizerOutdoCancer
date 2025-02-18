import SwiftUI

struct ADCCheckmarkButton: View {
    let action: () -> Void
    let isEnabled: Bool

    // State variable to drive the pulsing scale effect
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        Button(action: action) {
            ZStack {
                // Circle that changes appearance based on isEnabled
                Image(systemName: "circle")
                    .font(.system(size: 60))
                    .symbolVariant(isEnabled ? .fill : .none)
                    .foregroundStyle(isEnabled ? .green : .white.opacity(0.3))
                    .animation(.easeInOut(duration: 0.3), value: isEnabled)
                
                // Checkmark that appears when enabled, with a pulsing scale effect
                Image(systemName: "checkmark")
                    .font(.system(size: 30))
                    .bold()
                    .foregroundStyle(.white)
                    .opacity(isEnabled ? 1 : 0.3)
                    // .scaleEffect(isEnabled ? pulseScale : 0.9)
                    // We handle pulsing via pulseScale, so no extra animation modifier here.
            }
            // .hoverEffect { effect, isActive, _ in
            //     effect.scaleEffect(isActive ? 1.15 : 1.0)
            // }
            .scaleEffect(isEnabled ? pulseScale : 0.9)
        }
        .frame(width: 60, height: 60)
        .contentShape(Rectangle())
        .disabled(!isEnabled)
        .onAppear {
            // Start pulsing if enabled on appear.
            if isEnabled {
                startPulsing()
            }
        }
        .onChange(of: isEnabled) { _, newValue in
            // When isEnabled changes, start or stop pulsing accordingly.
            if newValue {
                startPulsing()
            } else {
                // Reset to the non-animated scale when disabled.
                pulseScale = 0.9
            }
        }
    }
    
    private func startPulsing() {
        // Reset pulseScale to the base value.
        pulseScale = 1.0
        // Animate pulseScale to 1.1 with a repeating animation.
        withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }
    }
}

//struct ADCCheckmarkButton_Previews: PreviewProvider {
//    static var previews: some View {
//        // Toggle isEnabled to see the pulsing effect in action.
//        VStack(spacing: 40) {
//            ADCCheckmarkButton(action: { print("Tapped!") }, isEnabled: true)
//            ADCCheckmarkButton(action: { print("Tapped!") }, isEnabled: false)
//        }
//        .padding()
//        .background(Color.gray.opacity(0.2))
//    }
//}
