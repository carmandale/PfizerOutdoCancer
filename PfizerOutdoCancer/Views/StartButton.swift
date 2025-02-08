//
//  StartButton.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 12/13/24.
//

import SwiftUI

struct StartButton: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some View {
        NavigationButton(
            title: "Start",
            action: {
                Task {
                    // Dismiss any open windows first
                    dismissWindow(id: AppModel.navWindowId)
                    appModel.isNavWindowOpen = false
                    
                    if !appModel.isMainWindowOpen {
                        openWindow(id: AppModel.mainWindowId)
                        appModel.isMainWindowOpen = true
                    }
                    await appModel.transitionToPhase(.intro)
                }
            },
            font: .title,
            scaleEffect: 1.2,
            width: 200
            
        )
        .fontWeight(.bold)
        .glassBackgroundEffect()
        .controlSize(.extraLarge)
        .hoverEffect { effect, isActive, proxy in
            effect
                .animation(.easeInOut(duration: 0.2)) {
                    $0.scaleEffect(isActive ? 1.1 : 1.0)
                }
        }
    }
}
//#Preview {
//    StartButton()
//}
