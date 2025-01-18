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

    var body: some View {
        Group {
            switch appModel.currentPhase {
            case .loading, .ready:
                LoadingView()
                    .onAppear { print("ContentView: Showing LoadingView") }
            case .building:
                ADCView()
                    .environment(adcDataModel)
                    .onAppear {
                        print("ContentView: About to show ADCView")
                        print("ContentView: isMainWindowOpen = \(appModel.isMainWindowOpen)")
                        print("ContentView: isBuilderInstructionsOpen = \(appModel.isBuilderInstructionsOpen)")
                    }
            case .playing:
                AttackCancerInstructionsView()
                    .environment(appModel)
                    .environment(adcDataModel)
                    .onAppear { print("ContentView: Showing AttackCancerInstructionsView") }
            case .completed:
                CompletedView()
                    .environment(appModel)
                    .environment(adcDataModel)
                    .onAppear { print("ContentView: Showing CompletedView") }
            default:
                EmptyView()
            }
        }
        .task {
            if appModel.currentPhase == .loading {
                await appModel.startLoading()
            }
        }
        .onAppear {
            appModel.isMainWindowOpen = true
        }
    }
}
