import SwiftUI
import RealityKit
import RealityKitContent

struct HopeMeterUtilityView: View {
    @Environment(AppModel.self) private var appModel
    
    private let height: CGFloat = 30
    private let fontSize: CGFloat = 20
    @State private var progressOpacity: Double = 0
    
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
                            withAnimation(.easeInOut(duration: 0.5)) {
                                appModel.startAttackCancerGame()
                            }
                        },
                        font: .title,
                        width: 250
                    )
                    .fontWeight(.bold)
                    .padding(.vertical, 30)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale),
                        removal: .opacity.combined(with: .scale).combined(with: .move(edge: .leading))
                    ))
                } else {
                    ZStack(alignment: .leading) {
                        // Background rectangle
                        RoundedRectangle(cornerRadius: height / 2)
                            .fill(Color("LightBlue200"))
                            .frame(height: height)
                        
                        // Progress rectangle using masking
                        RoundedRectangle(cornerRadius: height / 2)
                            .fill(Color("gradient600"))
                            .frame(height: height)
                            .mask(
                                GeometryReader { geometry in
                                    RoundedRectangle(cornerRadius: height / 2)
                                        .frame(width: geometry.size.width * progress)
                                        .animation(.linear(duration: 0.5), value: progress)
                                }
                            )
                        
                        // Percentage text
                        Text("\(percentage)%")
                            .font(.system(size: fontSize))
                            .bold()
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(width: 598)
                    .padding(.vertical, 30)
                    .opacity(progressOpacity)
                    .onAppear {
                        withAnimation(.easeIn(duration: 0.7)) {
                            progressOpacity = 1.0
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale).combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .scale)
                    ))
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
