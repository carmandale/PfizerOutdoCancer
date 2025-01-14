//
//  AttackCancerViewerButton.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 12/13/24.
//

import SwiftUI

struct LabViewerButton: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        Button {
            Task {
//                openWindow(id: AppModel.mainWindowId)
                await appModel.transitionToPhase(.lab, adcDataModel: dataModel)
            }
        } label: {
            Text("Enter The Lab")
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
