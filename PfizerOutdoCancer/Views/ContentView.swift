//
//  ContentView.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 12/22/24.
//
import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) var adcDataModel
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            switch appModel.currentPhase {
            case .loading, .ready, .intro:
                LoadingView()
                    .environment(appModel)
                    .environment(adcDataModel)
            case .building:
                ADCView()
                    .environment(adcDataModel)
            case .playing:
                if appModel.isInstructionsWindowOpen {
                    AttackCancerInstructionsView()
                        .environment(appModel)
                        .environment(adcDataModel)
                }
            case .completed:
                CompletedView()
                    .environment(appModel)
                    .environment(adcDataModel)
            case .outro:
                EmptyView()
            default:
                EmptyView()
            }
        }
        .onAppear {
            appModel.isMainWindowOpen = true
        }
    }
}
