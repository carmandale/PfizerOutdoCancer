import SwiftUI

struct ErrorView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("An Error Occurred")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text("We encountered an issue while loading assets.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: {
                // Optionally, provide a way to retry loading assets
                // For example, reset the gamePhase and start loading again
                // appModel.gamePhase = .setup
            }) {
                Text("Retry")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .padding()
    }
} 