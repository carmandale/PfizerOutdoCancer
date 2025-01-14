import SwiftUI

struct LoadingView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var showTitle = false

    var body: some View {
        Group {
            if case .completed = appModel.loadingState {
                // Nothing - view will be empty when loading completes
            } else {
                VStack {
                    Image("Pfizer_Logo_Color_RGB")
                        .resizable()
                        .scaledToFit()
                        .padding(80)
                    
                    if showTitle {
                        Text("Let's Outdo Cancer")
                            .font(.extraLargeTitle)
                            .transition(WordByWordTransition(
                                totalDuration: 2.0,    // Total animation duration
                                elementDuration: 0.8,   // Duration for each word
                                extraBounce: 0.2       // More bounce in the spring animation
                            ))
                    }
                        
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
                .frame(width: 800, height: 600)
                .onChange(of: appModel.loadingState) {
                    print("Loading state changed")
                    print("Loading progress: \(appModel.loadingProgress)")
                    print("Loading state: \(appModel.loadingState)")
                    dismissWindow()
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
    }
}


//#Preview(windowStyle: .automatic) {
//    LoadingView()
//        .environment(AppModel())
//}
