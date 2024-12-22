import SwiftUI
import RealityKit
import RealityKitContent

struct CompletedView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var animateStats = false
    
    private var stats: (destroyed: Int, deployed: Int, score: Int) {
        let gameState = appModel.gameState
        return (
            destroyed: gameState.cellsDestroyed,
            deployed: gameState.totalADCsDeployed,
            score: gameState.score
        )
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Text("Mission Complete")
                    .font(.largeTitle)
                    .bold()
                
                Text("Outstanding work!")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 16)
            
            // Stats
            VStack(spacing: 16) {
                statRow("Cancer Cells Destroyed", value: stats.destroyed, icon: "target")
                statRow("ADCs Deployed", value: stats.deployed, icon: "arrow.up.forward")
                statRow("Final Score", value: stats.score, icon: "star.fill")
            }
            .padding(.vertical, 20)
            
            // Buttons
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button(action: {
                        resetAndStartNew()
                        Task {
                            await appModel.transitionToPhase(.playing)
                        }
                    }) {
                        Label("Replay", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .frame(width: 180)
                    
                    Button(action: {
                        resetAndStartNew()
                        Task {
                            await appModel.transitionToPhase(.lab)
                        }
                    }) {
                        Label("Return to Lab", systemImage: "building.2")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .frame(width: 180)
                }
            }
        }
        .padding(48)
        .glassBackgroundEffect()
        .frame(maxWidth: 400)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(32)
        .onAppear {
            withAnimation(.easeOut) {
                animateStats = true
            }
        }
    }
    
    private func statRow(_ title: String, value: Int, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(value)")
                .bold()
                .monospacedDigit()
        }
        .frame(width: 372) // Width of both buttons (180 * 2) + spacing (12)
        .padding()
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func resetAndStartNew() {
        animateStats = false
        appModel.gameState.resetGameState()
    }
}

//// MARK: - Preview
//#Preview {
//    CompletedView()
//        .environment(AppModel())  // Using your existing AppModel
//}
