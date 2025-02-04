import SwiftUI
import RealityKit
import RealityKitContent

struct CompletedView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel
    @Environment(\.openWindow) private var openWindow
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
                statRow("ADCs Deployed", value: stats.deployed, icon: "arrow.up.forward")
            }
            .padding(.vertical, 20)
            
            // Buttons
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await appModel.transitionToPhase(.outro)
                        }
                    }) {
                        Label("Continue", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .glassBackgroundEffect()
                }
            }
        }
        .padding(64)
        .frame(maxWidth: 500)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .glassBackgroundEffect()
        .padding(32)
        .onAppear {
            dismissWindow(id: AppModel.navWindowId)
            
            withAnimation(.easeOut) {
                animateStats = true
            }
        }
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
        .frame(width: 372)
        .padding()
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

//// MARK: - Preview
//#Preview {
//    CompletedView()
//        .environment(AppModel())  // Using your existing AppModel
//        .environment(ADCDataModel())
//}
