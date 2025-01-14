import SwiftUI
import RealityKit
import RealityKitContent

struct HopeMeterView: View {
    @Environment(AppModel.self) private var appModel
    
    private let lineWidth: CGFloat = 12
    private let fontSize: CGFloat = 65
    
    var progress: CGFloat {
        1.0 - (CGFloat(appModel.gameState.hopeMeterTimeLeft) / CGFloat(appModel.gameState.hopeMeterDuration))
    }
    
    var percentage: Int {
        Int(progress * 100)
    }
    
    var body: some View {
        ZStack {
            VStack {
                Text("Hope Meter")
                    .font(.system(size: fontSize / 4))
                    .bold()
                Spacer()
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(lineWidth: lineWidth)
                        .opacity(0.2)
                        .foregroundColor(.gray)
                        .frame(width: 120, height: 120)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: progress)
                        .frame(width: 120, height: 120)
                    
                    // Percentage text
                    Text("\(percentage)%")
                        .font(.system(size: fontSize / 2))
                        .bold()
                        .shadow(color: .black, radius: 10, x: 0, y: 0)
                        .monospacedDigit()
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: 160, height: 160)
        .padding(30)
        .background(.clear)
    }
}


#Preview {
    
    HopeMeterView()
        .environment(AppModel())
}
