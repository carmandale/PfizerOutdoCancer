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
    var scaleEffect: CGFloat = 1.2
    
    var body: some View {
        ZStack {
            // Outer gradient border
            Capsule()
                .frame(width: 400, height: 250)
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [
                    Color("gradient800"),  // 800: hsla(240,100,20,1)
                    Color("gradient600"),  // 600: hsla(240,100,39,1)
                    Color("gradient400"),   // 400: hsla(205,100,50,1)
                    Color("gradient200"), // 200: hsla(198,100,70,1)
                    Color("gradient050") // 050: hsla(199,100,94,1)
                ]), startPoint: .top, endPoint: .bottom))
                .rotationEffect(.degrees(rotation))
                .hoverEffect(.highlight)
                .mask {
                    Capsule()
                        .stroke(lineWidth: 20)
                        .frame(width: 200, height: 60)
                        .blur(radius: 10)
                }
                .hoverEffect { effect, isActive, proxy in
                    effect.scaleEffect(!isActive ? 1.0 : scaleEffect)
                }
            
            // Inner gradient border
            Capsule()
                .frame(width: 400, height: 250)
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [
                    Color("gradient800"),  // 800: hsla(240,100,20,1)
                    Color("gradient600"),  // 600: hsla(240,100,39,1)
                    Color("gradient400"),   // 400: hsla(205,100,50,1)
                    Color("gradient200"), // 200: hsla(198,100,70,1)
                    Color("gradient050") // 050: hsla(199,100,94,1)
                ]), startPoint: .top, endPoint: .bottom))
                .rotationEffect(.degrees(rotation))
                .hoverEffect(.highlight)
                .mask {
                    Capsule()
                        .stroke(lineWidth: 10)
                        .frame(width: 200, height: 60)
                }
                .hoverEffect { effect, isActive, proxy in
                    effect.scaleEffect(!isActive ? 1.0 : scaleEffect)
                }
            
            // Background gradient
            // Capsule()
            //     .frame(width: 400 , height: 250)
            //     .foregroundStyle(LinearGradient(gradient: Gradient(colors: [
            //         Color("gradient800").opacity(0.4),
            //         Color("gradient600").opacity(0.4),
            //         Color("gradient400").opacity(0.4),
            //         Color("gradient200").opacity(0.4)
            //     ]), startPoint: .top, endPoint: .bottom))
            //     .rotationEffect(.degrees(rotation))
            //     .mask {
            //         Capsule()
            //             .stroke(lineWidth: 8)
            //             .frame(width: 200, height: 60)
            //     }
            //     .hoverEffect { effect, isActive, proxy in
            //         effect.scaleEffect(!isActive ? 1.0 : scaleEffect)
            //     }
            
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
    }
}

//#Preview {
//    ADCBuilderViewerButton()
//        .environment(AppModel())
//}
