import SwiftUI

struct LoadingView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissWindow) private var dismissWindow

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
                    Text("Let's Outdo Cancer")
                        .font(.extraLargeTitle)
                        
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
            }
        }
    }
}


//#Preview(windowStyle: .automatic) {
//    LoadingView()
//        .environment(AppModel())
//}
