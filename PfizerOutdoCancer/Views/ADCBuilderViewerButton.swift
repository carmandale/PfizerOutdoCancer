//
//  ADCBuilderViewerButton.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 12/13/24.
//

import SwiftUI

struct ADCBuilderViewerButton: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    var body: some View {
        Button {
            Task {
                print("main window status: \(appModel.isMainWindowOpen)")
                // if !appModel.isMainWindowOpen {
                //     print("opening builder window")
                //     print("current phase: \(appModel.currentPhase)")
                //     print("opening main window")
                //     openWindow(id: AppModel.mainWindowId)
                //     appModel.isMainWindowOpen = true
                // } else {
                //     print("main window already open")
                // }
                print("builder window status: \(appModel.isBuilderInstructionsOpen)")
                print("setting builder window status to true")
                await appModel.transitionToPhase(.building)
                appModel.isBuilderInstructionsOpen = true
            }
        } label: {
            Text("ADC Builder")
                .font(.title)
                .fontWeight(.bold)
                .padding()
                .frame(minWidth: 200)
        }
        .glassBackgroundEffect()
        .controlSize(.extraLarge)
        .buttonStyle(.plain)
    }
}

//#Preview {
//    ADCBuilderViewerButton()
//        .environment(AppModel())
//}
