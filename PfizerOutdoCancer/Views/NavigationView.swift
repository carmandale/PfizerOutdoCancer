import SwiftUI
import RealityKitContent

struct NavigationView: View {
    @Environment(AppModel.self) private var appModel
    
    private let buttonTitles = ["Intro", "Lab", "Building", "Attack"]
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(buttonTitles, id: \.self) { title in
                NavigationButton(title: title) {
                    await appModel.transitionToPhase(phaseFor(title))
                }
                .frame(width: 200)
            }
        }
        .padding(4)
    }
    
    private func phaseFor(_ title: String) -> AppPhase {
        switch title {
        case "Intro": return .intro
        case "Lab": return .lab
        case "Building": return .building
        case "Attack": return .playing
        default: return .intro
        }
    }
}

struct NavigationButton: View {
    let title: String
    let action: () async -> Void
    
    var body: some View {
        Button {
            Task { await action() }
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
        }
    }
}
