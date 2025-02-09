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
    @State private var rotation: CGFloat = 0.0
    @State private var currentTheme: GradientTheme = .lightBlue
    var scaleEffect: CGFloat = 1.2
    var width: CGFloat = 400
    var height: CGFloat = 250
    
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
            width: 200,
            theme: currentTheme,
            gradientWidth: width,
            gradientHeight: height
        )
        .fontWeight(.bold)
        .controlSize(.extraLarge)
        .opacity(appModel.labState.shouldShowADCButton ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appModel.labState.shouldShowADCButton)
        .transition(Appear())
    }
}

//#Preview {
//    ADCBuilderViewerButton()
//        .environment(AppModel())
//}
