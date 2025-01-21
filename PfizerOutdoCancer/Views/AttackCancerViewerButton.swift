//
//  AttackCancerViewerButton.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 12/13/24.
//

import SwiftUI

struct AttackCancerViewerButton: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        Button {
            Task {
                if !appModel.isMainWindowOpen {
                    openWindow(id: AppModel.mainWindowId)
                    appModel.isMainWindowOpen = true
                }
                appModel.isInstructionsWindowOpen = true
                await appModel.transitionToPhase(.playing, adcDataModel: dataModel)
            }
        } label: {
            Text("Attack Cancer")
                .font(.title)
                .fontWeight(.bold)
                .padding()
                .frame(minWidth: 200)
        }
//        .padding()
        .glassBackgroundEffect()
        .controlSize(.extraLarge)
        .buttonStyle(.plain)
    }
}

//#Preview {
//    AttackCancerViewerButton()
//}
