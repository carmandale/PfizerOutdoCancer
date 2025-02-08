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
            VStack(spacing: 0) {
                // Header with logo and title
                ZStack {
                    HStack {
                        Image("Pfizer_Logo_White_RGB")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100)
                        Spacer()
                    }
                    
                    Text("Hope Meter")
                        .font(.largeTitle)
                }
                .padding(30)
                .background(.black.opacity(0.4))
                .frame(width: 648)
                
                // Content section
                if !appModel.gameState.isHopeMeterRunning {
                    NavigationButton(
                        title: "Start",
                        action: {
                            appModel.startAttackCancerGame()
                        },
                        font: .title,
                        scaleEffect: AppModel.buttonExpandScale,
                        width: 250
                    )
                    .fontWeight(.bold)
                    .glassBackgroundEffect()
                    .hoverEffect { effect, isActive, proxy in
                        effect
                            .animation(.easeInOut(duration: 0.2)) {
                                $0.scaleEffect(isActive ? AppModel.buttonExpandScale : 1.0)
                            }
                    }
                    .padding(.vertical, 30)
                } else {
                    ZStack(alignment: .leading) {
                        // Background rectangle
                        RoundedRectangle(cornerRadius: height / 2)
                            .fill(Color("LightBlue200"))
                            .frame(height: height)
                        
                        // Progress rectangle
                        RoundedRectangle(cornerRadius: height / 2)
                            .fill(Color("gradient600"))
                            .frame(width: 598 * progress, height: height)
                            .animation(.linear(duration: 0.5), value: progress)
                        
                        // Percentage text
                        Text("\(percentage)%")
                            .font(.system(size: fontSize))
                            .bold()
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(width: 598)
                    .padding(.vertical, 30)
                    .transition(Appear())
                }
            }
            .frame(width: 648)
            .frame(alignment: .top)
            .glassBackgroundEffect()
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .transition(Appear())
        }
    }
}

//#Preview {
//    HopeMeterUtilityView()
//        .environment(AppModel())
//}
