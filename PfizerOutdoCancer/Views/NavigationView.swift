import SwiftUI
import RealityKitContent

struct NavigationView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) private var dataModel
    @Environment(\.openWindow) private var openWindow
    
    private let buttonTitles = ["Intro", "Lab", "Building", "Attack"]
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(buttonTitles, id: \.self) { title in
                NavigationButton(title: title) {
                    await handleNavigation(for: title)
                }
                .frame(width: 150)
                .glassBackgroundEffect()
            }
            
        }
        .padding(20)
        .glassBackgroundEffect()
    }
    
    private func handleNavigation(for title: String) async {
        switch title {
        case "Building":
            appModel.isBuilderInstructionsOpen = true
            await appModel.transitionToPhase(.building)
        case "Attack":
//            openWindow(id: AppModel.mainWindowId)
            await appModel.transitionToPhase(.playing, adcDataModel: dataModel)
        default:
            await appModel.transitionToPhase(phaseFor(title))
        }
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
                .padding(16)
        }
//        .padding(16)
        .buttonStyle(.plain)
    }
}


#Preview {
    NavigationView()
        .environment(AppModel())
        .environment(ADCDataModel())
}
