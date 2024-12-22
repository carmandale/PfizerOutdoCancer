import SwiftUI
import RealityKit
import RealityKitContent

struct HopeMeterView: View {
    @Environment(AppModel.self) private var appModel: AppModel
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private let lineWidth: CGFloat = 12
    private let fontSize: CGFloat = 75
    
    var progress: CGFloat {
        CGFloat(appModel.gameState.hopeMeterTimeLeft) / CGFloat(appModel.gameState.hopeMeterDuration)
    }
    
    var body: some View {
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
            
            // Timer text
            Text("\(Int(ceil(appModel.gameState.hopeMeterTimeLeft)))")
                .font(.system(size: fontSize))
                .foregroundColor(.white)
        }
        .frame(width: 160, height: 160)
        .padding(30)
        .background(.clear)
        .onReceive(timer) { _ in
            if appModel.gameState.isHopeMeterRunning {
                if appModel.gameState.hopeMeterTimeLeft > 0 {
                    appModel.gameState.hopeMeterTimeLeft -= 1
                } else {
                    appModel.gameState.isHopeMeterRunning = false
                    appModel.currentPhase = .completed
                }
            }
        }
    }
}
