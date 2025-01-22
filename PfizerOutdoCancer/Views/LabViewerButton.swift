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
        NavigationButton(
            title: "Enter The Lab",
            action: {
                Task {
                    await appModel.transitionToPhase(.lab, adcDataModel: dataModel)
                }
            },
            font: .title,
            scaleEffect: 1.1,
            width: 250
        )
        .fontWeight(.bold)
        .glassBackgroundEffect()
        .controlSize(.extraLarge)
        .hoverEffect(.highlight)
        .hoverEffect { effect, isActive, proxy in
            effect.scaleEffect(!isActive ? 1.0 : 1.05)
        }
    }
}

//#Preview {
//    AttackCancerViewerButton()
//}
