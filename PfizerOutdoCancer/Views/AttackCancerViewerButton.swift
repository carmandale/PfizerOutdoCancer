//
//  AttackCancerViewerButton.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 12/13/24.
//

import SwiftUI

// Color theme enum for testing different combinations
enum GradientTheme: CaseIterable {
    case darkRed
    case lightRed
    case lightGreen
    case lightMustard
    case lightBlue
    
    var colors: [Color] {
        switch self {
        case .darkRed:
            return [
                Color("DarkRed800"),
                Color("DarkRed600"),
                Color("DarkRed400"),
                Color("DarkRed200"),
                Color("DarkRed050")
            ]
        case .lightRed:
            return [
                Color("LightRed800"),
                Color("LightRed600"),
                Color("LightRed400"),
                Color("LightRed200"),
                Color("LightRed050")
            ]
        case .lightGreen:
            return [
                Color("LightGreen800"),
                Color("LightGreen600"),
                Color("LightGreen400"),
                Color("LightGreen200"),
                Color("LightGreen050")
            ]
        case .lightMustard:
            return [
                Color("LightMustard800"),
                Color("LightMustard600"),
                Color("LightMustard400"),
                Color("LightMustard200"),
                Color("LightMustard050")
            ]
        case .lightBlue:
            return [
                Color("LightBlue800"),
                Color("LightBlue600"),
                Color("LightBlue400"),
                Color("LightBlue200"),
                Color("LightBlue050")
            ]
        }
    }
}

struct AttackCancerViewerButton: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel
    @Environment(\.openWindow) private var openWindow
    @State private var rotation: CGFloat = 0.0
    @State private var currentTheme: GradientTheme = .lightMustard
    var scaleEffect: CGFloat = 1.2
    var width: CGFloat = 450
    var height: CGFloat = 350
    
    // MARK: - Debug Controls
    #if DEBUG
    private let isDebugMode = false
    #else
    private let isDebugMode = false
    #endif
    
    private var shouldShowButton: Bool {
        // Only show in debug mode or when ADC is built AND lab is ready
        isDebugMode || (appModel.hasBuiltADC && appModel.readyToStartLab)
    }
    
    private func cycleTheme() {
        guard let currentIndex = GradientTheme.allCases.firstIndex(of: currentTheme) else { return }
        let nextIndex = (currentIndex + 1) % GradientTheme.allCases.count
        currentTheme = GradientTheme.allCases[nextIndex]
    }
    
    var body: some View {
        Group {
            if shouldShowButton {
                NavigationButton(
                    title: "Attack Cancer",
                    action: {
                        if isDebugMode {
                            cycleTheme()
                        } else {
                            Task {
                                // if !appModel.isMainWindowOpen {
                                //     openWindow(id: AppModel.mainWindowId)
                                //     appModel.isMainWindowOpen = true
                                // }

                                appModel.playMenuSelect2Sound()

                                appModel.isInstructionsWindowOpen = true
                                await appModel.transitionToPhase(.playing, adcDataModel: dataModel)
                            }
                        }
                    },
                    font: .title,
                    scaleEffect: AppModel.UIConstants.buttonExpandScale,
                    width: 250,
                    theme: currentTheme,
                    gradientWidth: width,
                    gradientHeight: height
                )
                .fontWeight(.bold)
                .onAppear {
                    withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
                .transition(Appear())
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: shouldShowButton && appModel.readyToStartLab)
    }
}

//#Preview {
//    AttackCancerViewerButton()
//}
