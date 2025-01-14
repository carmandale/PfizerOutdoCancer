import SwiftUI

struct ADCStartImmersiveButton: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel
    
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some View {
        Button {
            Task { @MainActor in
                switch appModel.immersiveSpaceState {
                    case .open:
//                        dataModel.status = .bloodVessel
                        appModel.immersiveSpaceState = .inTransition
                        openWindow(id: AppModel.builderWindowId)
                        
                    
                        await dismissImmersiveSpace()
                        // Don't set immersiveSpaceState to .closed because there
                        // are multiple paths to ImmersiveView.onDisappear().
                        // Only set .closed in ImmersiveView.onDisappear().

                    case .closed:
                        appModel.immersiveSpaceState = .inTransition
//                        dataModel.status = .bloodVesselGame
                    switch await openImmersiveSpace(id: AppModel.buildingSpaceId) {
                            case .opened:
                                appModel.isBuilderInstructionsOpen = false
                                // Don't set immersiveSpaceState to .open because there
                                // may be multiple paths to ImmersiveView.onAppear().
                                // Only set .open in ImmersiveView.onAppear().
                                dismissWindow(id: AppModel.mainWindowId)
                                appModel.isMainWindowOpen = false
                                break

                            case .userCancelled, .error:
                                // On error, we need to mark the immersive space
                                // as closed because it failed to open.
                                fallthrough
                            @unknown default:
                                // On unknown response, assume space did not open.
//                                dataModel.status = .bloodVessel
                                appModel.immersiveSpaceState = .closed
                        }

                    case .inTransition:
                        // This case should not ever happen because button is disabled for this case.
                        break
                }
            }
        } label: {
            Text(appModel.immersiveSpaceState == .open ? "Exit builder" : "Start Building")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .glassBackgroundEffect()
//                .background(Color(hex: 0x0000c9))
//                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

//#Preview {
//    ADCStartImmersiveButton()
//        .frame(width: 400, height: 400)
//        .glassBackgroundEffect()
//        .environment(ADCAppModel())
//        .environment(ADCDataModel())
//}
