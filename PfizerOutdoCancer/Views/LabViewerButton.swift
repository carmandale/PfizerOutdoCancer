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
            scaleEffect: AppModel.buttonExpandScale,
            width: 250
        )
        .fontWeight(.bold)
        .glassBackgroundEffect()
        .hoverEffect { effect, isActive, proxy in
            effect
                .animation(.easeInOut(duration: 0.2)) {
                    $0.scaleEffect(isActive ? AppModel.buttonExpandScale : 1.0)
                }
        }
    }
}

//#Preview {
//    AttackCancerViewerButton()
//}
