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
        ZStack {
            // Outer gradient border
            Capsule()
                .frame(width: width, height: height)
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: currentTheme.colors), 
                    startPoint: .top, endPoint: .bottom))
                .rotationEffect(.degrees(rotation))
                .hoverEffect(.highlight)
                .mask {
                    Capsule()
                        .stroke(lineWidth: 20)
                        .frame(width: 200, height: 60)
                        .blur(radius: 10)
                }
                .hoverEffect { effect, isActive, proxy in
                    effect
                        .animation(.easeInOut(duration: 0.2)) {
                            $0.scaleEffect(isActive ? AppModel.buttonExpandScale : 1.0)
                        }
                }
            
            // Inner gradient border
            Capsule()
                .frame(width: width, height: height)
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: currentTheme.colors), 
                    startPoint: .top, endPoint: .bottom))
                .rotationEffect(.degrees(rotation))
                .hoverEffect(.highlight)
                .mask {
                    Capsule()
                        .stroke(lineWidth: 10)
                        .frame(width: 200, height: 60)
                }
                .hoverEffect { effect, isActive, proxy in
                    effect
                        .animation(.easeInOut(duration: 0.2)) {
                            $0.scaleEffect(isActive ? AppModel.buttonExpandScale : 1.0)
                        }
                }
            
            // Button
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
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
        .opacity(appModel.labState.shouldShowADCButton ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appModel.labState.shouldShowADCButton)
        .transition(Appear())
    }
}

//#Preview {
//    ADCBuilderViewerButton()
//        .environment(AppModel())
//}
