import SwiftUI
import RealityKit
import RealityKitContent

struct CompletedView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var animateStats = false
    @State private var opacity: Double = 0  // Add state for opacity
    
    private var stats: (destroyed: Int, deployed: Int, score: Int) {
        let gameState = appModel.gameState
        return (
            destroyed: gameState.cellsDestroyed,
            deployed: gameState.totalADCsDeployed,
            score: gameState.score
        )
    }
        
    var body: some View {

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
                    
                    Text("Mission Complete")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 30)

                    Text("Outstanding work!")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 50)
                }
                .padding(30)
                .background(.black.opacity(0.4))
                .frame(width: 648)
                
                // Content section
                VStack {
                    statRow("ADCs Deployed", value: stats.deployed, icon: "arrow.up.forward")
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 100)
                
                NavigationButton(
                    title: "Continue",
                    action: {
                        Logger.info("=== Starting Transition to Outro ===")
                                Logger.info("Current Phase: \(appModel.currentPhase)")
                                Logger.info("Immersive Space State: \(appModel.immersiveSpaceState)")
                                
                                // Start fade out sequence
                                withAnimation(.easeOut(duration: 1.0)) {
                                    opacity = 0.0
                                }
                                
                                // After window fades, transition to outro
                                Task {
                                    appModel.playMenuSelectSound()
                                    try? await Task.sleep(for: .seconds(1.0))
                                    await appModel.transitionToPhase(.outro)
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
                
            }
            .frame(width: 648)
            .frame(alignment: .top)
            .glassBackgroundEffect()
//            .background(
//                    Color.white
//                        .opacity(0.5)
//                        .cornerRadius(20)
//                )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .opacity(opacity) 
            .onAppear {
                    withAnimation(.easeIn(duration: 2.0)) {
                        opacity = 1.0
                    }
                }
            .onDisappear {
                withAnimation(.easeOut(duration: 1.0)) {
                    opacity = 1.0
                }
            } // Single opacity modifier for the entire view
            .transition(Appear())
    }

    // Helper functions moved outside of body
    private func statRow(_ title: String, value: Int, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.title2)
                .bold()
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(value)")
                .font(.title)
                .bold()
                .monospacedDigit()
        }
    }
}
