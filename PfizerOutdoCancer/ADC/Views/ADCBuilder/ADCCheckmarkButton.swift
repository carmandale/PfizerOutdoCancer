import SwiftUI

struct ADCCheckmarkButton: View {
    let action: () -> Void
    let isEnabled: Bool
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Circle that changes color
                Image(systemName: "circle")
                    .font(.system(size: 60))
                    .symbolVariant(isEnabled ? .fill : .none)
                    .foregroundStyle(isEnabled ? .green : .white.opacity(0.3))
                    .animation(.easeInOut(duration: 0.3), value: isEnabled)
                    
                
                // White checkmark that appears when enabled
                Image(systemName: "checkmark")
                    .font(.system(size: 30))
                    .bold()
                    .foregroundStyle(.white)
                    .opacity(isEnabled ? 1 : 0.3)
                    .scaleEffect(isEnabled ? 1 : 0.9)
                    .animation(.spring(response: 0.3), value: isEnabled)
            }
            .hoverEffect { effect, isActive, _ in
                effect.scaleEffect(isActive ? 1.15 : 1.0)
            }
        }
        .frame(width: 60, height: 60)
        .contentShape(Rectangle())
        .disabled(!isEnabled)
    }
} 

//#Preview {
//    ADCCheckmarkButton()
//}
