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
//                statRow("Cancer Cells Destroyed", value: stats.destroyed, icon: "target")
                statRow("ADCs Deployed", value: stats.deployed, icon: "arrow.up.forward")
//                statRow("Final Score", value: stats.score, icon: "star.fill")
            }
            .padding(.vertical, 20)
            
            // Buttons
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                //    Button(action: {
                //        resetAndStartNew()
                //        Task {
                //            if !appModel.isMainWindowOpen {
                //                openWindow(id: AppModel.mainWindowId)
                //                appModel.isMainWindowOpen = true
                //            }
                //            await appModel.transitionToPhase(.playing, adcDataModel: dataModel)
                //        }
                //    }) {
                //        Label("Replay", systemImage: "arrow.clockwise")
                //            .frame(maxWidth: .infinity)
                //    }
                //    .glassBackgroundEffect()
                //    .frame(width: 180)
                    
                //     Button(action: {
                //         Task {
                //             print("main window status: \(appModel.isMainWindowOpen)")
                //             if !appModel.isMainWindowOpen {
                //                 openWindow(id: AppModel.mainWindowId)
                //                 appModel.isMainWindowOpen = true
                //             }
                //             await appModel.transitionToPhase(.lab)
                //         }
                //     }) {
                //         Label("Return to Lab", systemImage: "building.2")
                //             .frame(maxWidth: .infinity)
                //     }
                //     .glassBackgroundEffect()
                //     .frame(width: 180)
                // }
                
                Button(action: {
                    Task {
                        // dismissWindow(id: AppModel.mainWindowId)
                        await appModel.transitionToPhase(.outro)
                    }
                }) {
                    Label("Continue", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .glassBackgroundEffect()
//                .frame(width: 372)
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
        .frame(width: 372) // Width of both buttons (180 * 2) + spacing (12)
        .padding()
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func resetAndStartNew() {
        animateStats = false
        
        // Don't call tearDownGame here since we want to preserve the environment
        // for the completion view
        appModel.gameState.resetGameState()  // This should only reset counters and stats
    }
}

//// MARK: - Preview
//#Preview {
//    CompletedView()
//        .environment(AppModel())  // Using your existing AppModel
//        .environment(ADCDataModel())
//}
