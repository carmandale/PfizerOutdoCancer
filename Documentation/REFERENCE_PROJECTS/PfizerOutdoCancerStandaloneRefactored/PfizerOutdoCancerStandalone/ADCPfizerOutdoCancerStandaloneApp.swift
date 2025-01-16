import SwiftUI

@main
struct ADCPfizerOutdoCancerStandaloneApp: App {

    @State private var appModel = ADCAppModel()
    @State private var dataModel = ADCDataModel()
    
    init() {
        ADCGestureComponent.registerComponent()
        ADCCameraSystem.registerSystem()
        ADCBillboardSystem.registerSystem()
        ADCSimpleBillboardSystem.registerSystem()
        ADCProximitySystem.registerSystem()
    }
    
    var body: some Scene {
        WindowGroup (id: ADCUIViews.mainViewID){
            ADCView()
                .environment(appModel)
                .environment(dataModel)
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)

        ImmersiveSpace(id: ADCUIViews.immersiveSpaceID) {
            ADCOptimizedImmersive()
                .environment(appModel)
                .environment(dataModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
