import SwiftUI
import RealityKitContent

struct NavigationView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) private var dataModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.scenePhase) private var scenePhase
    
    private let buttonTitles = ["Lab", "Building", "Attack", "Outro"]
    
    var body: some View {
        HStack(spacing: 30) {
            ForEach(buttonTitles, id: \.self) { title in
                NavigationButton(
                    title: title,
                    action: { await handleNavigation(for: title) },
                    width: 150
                )
                .fontWeight(.bold)
            }
        }
        .padding(20)
        .glassBackgroundEffect()
        .opacity(appModel.isNavWindowOpen ? 1 : 0)
        .animation(.default, value: appModel.isNavWindowOpen)
        
        .onChange(of: scenePhase, initial: true) { oldPhase, newPhase in
            switch newPhase {
            case .inactive, .background:
                appModel.isNavWindowOpen = false
            default:
                break
            }
        }
    }
    
    private func handleNavigation(for title: String) async {
        switch title {
        case "Building":
            appModel.isBuilderInstructionsOpen = true
            await appModel.transitionToPhase(.building)
        case "Attack":
            appModel.isInstructionsWindowOpen = true
            await appModel.transitionToPhase(.playing, adcDataModel: dataModel)
        default:
            await appModel.transitionToPhase(phaseFor(title))
        }
    }
    
    private func phaseFor(_ title: String) -> AppPhase {
        switch title {
        case "Lab": return .lab
        case "Building": return .building
        case "Attack": return .playing
        case "Outro": return .outro
        default: return .lab
        }
    }
}

//#Preview {
//    NavigationView()
//        .environment(AppModel())
//        .environment(ADCDataModel())
//}
