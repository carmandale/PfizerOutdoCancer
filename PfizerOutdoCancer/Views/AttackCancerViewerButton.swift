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
        isDebugMode || appModel.hasBuiltADC
    }
    
    private func cycleTheme() {
        guard let currentIndex = GradientTheme.allCases.firstIndex(of: currentTheme) else { return }
        let nextIndex = (currentIndex + 1) % GradientTheme.allCases.count
        currentTheme = GradientTheme.allCases[nextIndex]
    }
    
    var body: some View {
        Group {
            if shouldShowButton {
                ZStack {
                    // Outer gradient border
                    Capsule()
                        .frame(width: width, height: height)
                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: currentTheme.colors), 
                            startPoint: .top, endPoint: .bottom))
                        .rotationEffect(.degrees(rotation))
                        .mask {
                            Capsule()
                                .stroke(lineWidth: 20)
                                .frame(width: 250, height: 60)
                                .blur(radius: 10)
                        }
                        .hoverEffect { effect, isActive, proxy in
                            effect
                                .animation(.easeInOut(duration: 0.2)) {
                                    $0.scaleEffect(isActive ? AppModel.UIConstants.buttonExpandScale : 1.0)
                                }
                        }
                    
                    // Inner gradient border
                    Capsule()
                        .frame(width: width, height: height)
                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: currentTheme.colors), 
                            startPoint: .top, endPoint: .bottom))
                        .rotationEffect(.degrees(rotation))
                        .mask {
                            Capsule()
                                .stroke(lineWidth: 10)
                                .frame(width: 250, height: 60)
                        }
                        .hoverEffect { effect, isActive, proxy in
                            effect
                                .animation(.easeInOut(duration: 0.2)) {
                                    $0.scaleEffect(isActive ? AppModel.UIConstants.buttonExpandScale : 1.0)
                                }
                        }
                    
                    // Button
                    NavigationButton(
                        title: "Attack Cancer",
                        action: {
                            if isDebugMode {
                                cycleTheme()
                            } else {
                                Task {
                                    if !appModel.isMainWindowOpen {
                                        openWindow(id: AppModel.mainWindowId)
                                        appModel.isMainWindowOpen = true
                                    }
                                    appModel.isInstructionsWindowOpen = true
                                    await appModel.transitionToPhase(.playing, adcDataModel: dataModel)
                                }
                            }
                        },
                        font: .title,
                        scaleEffect: AppModel.UIConstants.buttonExpandScale,
                        width: 250
                    )
                    .fontWeight(.bold)
                    .glassBackgroundEffect()
                }
                .onAppear {
                    withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
                .transition(Appear())
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: shouldShowButton)
    }
}

//#Preview {
//    AttackCancerViewerButton()
//}
