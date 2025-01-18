
import SwiftUI

struct StartView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var showTitle = false

    var body: some View {
        Group {
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
                    StartButton()
                    
                }
                .frame(width: 800, height: 600)
                
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



//#Preview(windowStyle: .automatic) {
//    StartView()
//        .environment(AppModel())
//}
