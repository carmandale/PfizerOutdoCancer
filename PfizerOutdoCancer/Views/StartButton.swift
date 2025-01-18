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
        Button {
            Task {
                // Dismiss any open windows first
                dismissWindow(id: AppModel.debugNavigationWindowId)
                appModel.isDebugWindowOpen = false
                
                if !appModel.isMainWindowOpen {
                    openWindow(id: AppModel.mainWindowId)
                    appModel.isMainWindowOpen = true
                }
                await appModel.transitionToPhase(.intro)
            }
        } label: {
            Text("Start")
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
//    StartButton()
//}
