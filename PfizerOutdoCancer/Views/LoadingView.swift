import SwiftUI

struct LoadingView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) private var adcDataModel
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var showTitle = false
    @State private var viewOpacity: Double = 1.0
    @State private var hasStartedLoading = false
    @Namespace private var logoNamespace
    
    var body: some View {
        ZStack {
            if case .loading = appModel.assetLoadingManager.loadingState {
                LoadingBlock(namespace: logoNamespace)
                    .environment(appModel)
            }
            if case .completed = appModel.assetLoadingManager.loadingState {
                CompletedBlock(namespace: logoNamespace)
                    .environment(appModel)
            }
        }
        .frame(width: 800, height: 600)
        .opacity(viewOpacity)
        .animation(.easeInOut(duration: 0.5), value: appModel.assetLoadingManager.loadingState)
        .onChange(of: appModel.assetLoadingManager.loadingState) { oldState, newState in
            
            if appModel.loadingProgress >= appModel.displayedProgress {
                withAnimation(.easeInOut(duration: 0.5)) {
                    appModel.displayedProgress = appModel.loadingProgress
                }
            } else {
                // If progress goes backward (resets to 0), update without animation
                appModel.displayedProgress = appModel.loadingProgress
            }
        }
        .onChange(of: appModel.introState.isSetupComplete) { _, complete in
            if complete {
                Logger.debug("Intro Setup Complete")
            }
        }
        .onChange(of: appModel.introState.startButtonPressed) { _, complete in
            Logger.debug("Start Button Pressed")
            withAnimation(.easeOut(duration: 0.25)) {
                viewOpacity = 0.0
            }
        }
        .onDisappear {
            print("🚨 LoadingView disappeared")
        }
        .task {
            // Start loading when LoadingView appears
            if !hasStartedLoading {
                hasStartedLoading = true
                await appModel.startLoading(adcDataModel: adcDataModel)
            }
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
                
                // Use displayedProgress here
                ProgressView(value: Double(appModel.displayedProgress))
                    .progressViewStyle(.linear)
                    .padding()
                    .transition(.opacity)
                
                Text("Please wait while we prepare your experience...")
                    .foregroundStyle(.secondary)
                    .padding()
                    .transition(.opacity)
                
                Text("build v57 - 3.26.25")
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
    @State private var showButton = false
    
    var body: some View {
        VStack {
            Image("Pfizer_Logo_Color_RGB")
                .resizable()
                .scaledToFit()
                .matchedGeometryEffect(id: "PfizerLogo", in: namespace)
                .frame(width: 400)
                .padding(40)
            
            // Title container with placeholder
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
            
            // Button container with placeholder
            ZStack {
                // Invisible placeholder to maintain layout
                StartButton()
                    .opacity(0)
                
                if showButton {
                    StartButton()
                        .transition(.opacity)
                }
            }
            .padding(.top, 50)
        }
        .onAppear {
            // Sequence animations
            Task { @MainActor in
                // First animate title
                try? await Task.sleep(for: .seconds(1.0))
                withAnimation {
                    showTitle = true
                }
                
                // Then fade in button after title animation starts
                try? await Task.sleep(for: .seconds(1.0))
                withAnimation(.easeInOut(duration: 0.5)) {
                    showButton = true
                }
            }
        }
    }
}

//#Preview(windowStyle: .automatic) {
//    LoadingView()
//        .environment(AppModel())
//}
