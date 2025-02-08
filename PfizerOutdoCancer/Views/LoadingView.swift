import SwiftUI

struct LoadingView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var showTitle = false
    @Namespace private var logoNamespace
    
    var body: some View {
        ZStack {
            if case .loading = appModel.loadingState {
                LoadingBlock(namespace: logoNamespace)
                    .environment(appModel)
            }
            if case .completed = appModel.loadingState {
                CompletedBlock(namespace: logoNamespace)
                    .environment(appModel)
            }
        }
        .frame(width: 800, height: 600)
        .animation(.easeInOut(duration: 0.5), value: appModel.loadingState)
        .onChange(of: appModel.loadingState) { oldState, newState in
            print("Loading state changed from \(oldState) to \(newState)")
            print("Loading progress: \(appModel.loadingProgress)")
        }
        .onDisappear {
            print("🚨 LoadingView disappeared")
        }
        .onAppear {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                withAnimation {
                    showTitle = true
                }
            }
        }
    }
}

private struct LoadingBlock: View {
    @Environment(AppModel.self) private var appModel
    let namespace: Namespace.ID
    
    var body: some View {
        VStack {
            Image("Pfizer_Logo_Color_RGB")
                .resizable()
                .scaledToFit()
                .matchedGeometryEffect(id: "PfizerLogo", in: namespace)
                .frame(width: 400)
                .padding(80)
            
            VStack {
                Text("Loading Assets...")
                    .font(.title)
                    .padding()
                    .transition(.opacity.combined(with: .scale))
                
                ProgressView(value: Double(appModel.loadingProgress))
                    .progressViewStyle(.linear)
                    .padding()
                    .transition(.opacity)
                
                Text("Please wait while we prepare your experience...")
                    .foregroundStyle(.secondary)
                    .padding()
                    .transition(.opacity)
                
                Text("build v43 - 2.7.25")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .padding()
                    .transition(.opacity)
            }
        }
    }
}

private struct CompletedBlock: View {
    @Environment(AppModel.self) private var appModel
    let namespace: Namespace.ID
    @State private var showTitle = false
    
    var body: some View {
        VStack {
            Image("Pfizer_Logo_Color_RGB")
                .resizable()
                .scaledToFit()
                .matchedGeometryEffect(id: "PfizerLogo", in: namespace)
                .frame(width: 400)
                .padding(40)
            
            // Add a fixed height container for the title
            ZStack {
                // Invisible placeholder text to maintain consistent layout
                Text("Let's Outdo Cancer")
                    .font(.extraLargeTitle)
                    .opacity(0)
                
                if showTitle {
                    Text("Let's Outdo Cancer")
                        .font(.extraLargeTitle)
                        .transition(WordByWordTransition(
                            totalDuration: 2.0,
                            elementDuration: 0.8,
                            extraBounce: 0.2
                        ))
                }
            }
            .padding()
            
            StartButton()
                .padding(.top, 50)
        }
        .onAppear {
            // Delay the title animation slightly to let the logo transition complete
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.3))
                withAnimation {
                    showTitle = true
                }
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    LoadingView()
        .environment(AppModel())
}
