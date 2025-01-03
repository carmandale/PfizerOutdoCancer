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
            case .loading:
                LoadingView()
            case .building:
                ADCView()
                    .environment(adcDataModel)
            default:
                EmptyView()
            }
        }
        .task {
            if appModel.currentPhase == .loading {
                await appModel.startLoading()
            }
        }
        .onChange(of: appModel.loadingState) {
            print("Loading state changed")
            print("Loading progress: \(appModel.loadingProgress)")
            print("Loading state: \(appModel.loadingState)")
            dismissWindow()
        }
    }
}
