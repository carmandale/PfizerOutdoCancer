import SwiftUI

struct LoadingView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

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
            }
        }
    }
}


//#Preview(windowStyle: .automatic) {
//    LoadingView()
//        .environment(AppModel())
//}
