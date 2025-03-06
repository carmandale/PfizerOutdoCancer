import SwiftUI
import RealityKitContent

struct NavigationView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) private var dataModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.scenePhase) private var scenePhase
    
    private let buttonTitles = ["ADC Builder", "Attack Cancer"]
    
    var body: some View {
        HStack(spacing: 30) {
            ForEach(buttonTitles, id: \.self) { title in
                NavigationButton(
                    title: title,
                    action: { await handleNavigation(for: title) },
                    width: 200
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
        case "ADC Builder":
            appModel.isBuilderInstructionsOpen = true
            await appModel.transitionToPhase(.building)
        case "Attack Cancer":
            appModel.isInstructionsWindowOpen = true
            await appModel.transitionToPhase(.playing, adcDataModel: dataModel)
        default:
            await appModel.transitionToPhase(phaseFor(title))
        }
    }
    
    private func phaseFor(_ title: String) -> AppPhase {
        switch title {
        case "ADC Builder": return .building
        case "Attack Cancer": return .playing
        default: return .lab
        }
    }
}

//#Preview {
//    NavigationView()
//        .environment(AppModel())
//        .environment(ADCDataModel())
//}
