import SwiftUI
import RealityKit
import RealityKitContent

struct HopeMeterUtilityView: View {
    @Environment(AppModel.self) private var appModel
    
    private let height: CGFloat = 30
    private let fontSize: CGFloat = 20
    
    var progress: CGFloat {
        1.0 - (CGFloat(appModel.gameState.hopeMeterTimeLeft) / CGFloat(appModel.gameState.hopeMeterDuration))
    }
    
    var percentage: Int {
        Int(progress * 100)
    }
    
    var body: some View {
        if appModel.currentPhase == .playing {
            VStack(spacing: 4) {
                if !appModel.gameState.isHopeMeterRunning {
                    Button("Start") {
                        appModel.startAttackCancerGame()
                    }
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(width: 648)
                    .padding()
                } else {
                    Text("Hope Meter")
                        .font(.system(size: fontSize))
                        .bold()
                    
                    ZStack(alignment: .leading) {
                        // Background rectangle
                        RoundedRectangle(cornerRadius: height / 2)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: height)
                        
                        // Progress rectangle
                        RoundedRectangle(cornerRadius: height / 2)
                            .fill(Color.blue)
                            .frame(width: 648 * progress, height: height)
                            .animation(.linear(duration: 0.5), value: progress)
                        
                        // Percentage text
                        Text("\(percentage)%")
                            .font(.system(size: fontSize))
                            .bold()
                            .foregroundColor(.white)
//                            .shadow(color: .black, radius: 5)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(width: 648)
                }
            }
            .padding(20)
            .glassBackgroundEffect()
        }
    }
}

//#Preview {
//    HopeMeterUtilityView()
//        .environment(AppModel())
//}
