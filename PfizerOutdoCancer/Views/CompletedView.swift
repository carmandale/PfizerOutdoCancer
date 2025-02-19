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
        
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    // Title
                    Text("Mission Complete")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 30)

                    Text("Outstanding work!")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    // Stats
                    VStack {
                        statRow("ADCs Deployed", value: stats.deployed, icon: "arrow.up.forward")
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 64)
            
                    // Buttons
                    VStack {
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
                                    try? await Task.sleep(for: .seconds(1.0))
                                    await appModel.transitionToPhase(.outro)
                                }
                            },
                            font: .title,
                            scaleEffect: AppModel.UIConstants.buttonExpandScale
                        )
                        .fontWeight(.bold)
                    }
                }
                .opacity(opacity)  // Apply opacity
                .onAppear {
                    withAnimation(.easeIn(duration: 2.0)) {
                        opacity = 1.0
                    }
                }
                .onDisappear {
                    withAnimation(.easeOut(duration: 1.0)) {
                        opacity = 1.0
                    }
                }
            }
        }
        .frame(minWidth: 500)
        .frame(minHeight: 500)
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
