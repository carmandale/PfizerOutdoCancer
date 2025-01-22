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
        NavigationButton(
            title: "ADC Builder",
            action: {
                Task {
                    print("builder window status: \(appModel.isBuilderInstructionsOpen)")
                    print("setting builder window status to true")
                    await appModel.transitionToPhase(.building)
                    appModel.isBuilderInstructionsOpen = true
                }
            },
            font: .title,
            scaleEffect: 1.1,
            width: 200

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
//    ADCBuilderViewerButton()
//        .environment(AppModel())
//}
