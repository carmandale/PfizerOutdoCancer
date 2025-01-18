import SwiftUI

struct LoadingView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var showTitle = false
    
    var body: some View {
        VStack {
            Image("Pfizer_Logo_Color_RGB")
                .resizable()
                .scaledToFit()
                .padding(80)
                .transition(.opacity)
            
            if case .completed = appModel.loadingState {
                Text("Let's Outdo Cancer")
                    .font(.extraLargeTitle)
                    .transition(WordByWordTransition(
                        totalDuration: 2.0,    // Total animation duration
                        elementDuration: 0.8,   // Duration for each word
                        extraBounce: 0.2       // More bounce in the spring animation
                    ))
            }
            
            if case .loading = appModel.loadingState {
                VStack {
                    Text("Loading Assets...")
                        .font(.title)
                        .padding()
                    
                    ProgressView(value: Double(appModel.loadingProgress))
                        .progressViewStyle(.linear)
                        .padding()
                    
                    Text("Please wait while we prepare your experience...")
                        .foregroundStyle(.secondary)
                        .padding()
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            if case .completed = appModel.loadingState {
                StartButton()
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .frame(width: 800, height: 600)
        .onChange(of: appModel.loadingState) { oldState, newState in
            print("Loading state changed from \(oldState) to \(newState)")
            print("Loading progress: \(appModel.loadingProgress)")
            
            if case .completed = newState {
//                dismissWindow()
            } else {
                withAnimation(.easeInOut(duration: 0.5)) {
                    // Let the state change drive the view updates
                }
            }
        }
        .onDisappear {
            print("🚨 LoadingView disappeared")
        }
        .onAppear {
            // Add 2 second delay before starting animation
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                withAnimation {
                    showTitle = true
                }
            }
        }
    }
}


//#Preview(windowStyle: .automatic) {
//    LoadingView()
//        .environment(AppModel())
//}
