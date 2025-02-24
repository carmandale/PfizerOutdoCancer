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
                    Logger.info("\n📍 Positioning Requested: Starting head tracking")
                    appModel.introState.shouldUpdateHeadPosition = true
                }
            },
            font: .title,
            scaleEffect: AppModel.UIConstants.buttonExpandScale,
            width: 200
        )
        .fontWeight(.bold)
    }
}
//#Preview {
//    StartButton()
//}
