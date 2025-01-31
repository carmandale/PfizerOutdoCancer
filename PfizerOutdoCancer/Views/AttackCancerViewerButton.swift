//
//  AttackCancerViewerButton.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 12/13/24.
//

import SwiftUI

struct AttackCancerViewerButton: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel
    @Environment(\.openWindow) private var openWindow
    @State private var rotation: CGFloat = 0.0
    var scaleEffect: CGFloat = 1.2
    
    var body: some View {
        ZStack {
            // Outer gradient border
            Capsule()
                .frame(width: 400, height: 250)
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0, blue: 0),     // Dark red
                    Color(red: 0.6, green: 0, blue: 0),     // Medium dark red
                    Color(red: 0.8, green: 0, blue: 0),     // Medium red
                    Color(red: 0.9, green: 0.1, blue: 0.1), // Lighter red
                    Color(red: 1.0, green: 0.2, blue: 0.2)  // Light red
                ]), startPoint: .top, endPoint: .bottom))
                .rotationEffect(.degrees(rotation))
                .hoverEffect(.highlight)
                .mask {
                    Capsule()
                        .stroke(lineWidth: 20)
                        .frame(width: 300, height: 60)
                        .blur(radius: 10)
                }
                .hoverEffect { effect, isActive, proxy in
                    effect.scaleEffect(!isActive ? 1.0 : scaleEffect)
                }
            
            // Inner gradient border
            Capsule()
                .frame(width: 400, height: 250)
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0, blue: 0),     // Dark red
                    Color(red: 0.6, green: 0, blue: 0),     // Medium dark red
                    Color(red: 0.8, green: 0, blue: 0),     // Medium red
                    Color(red: 0.9, green: 0.1, blue: 0.1), // Lighter red
                    Color(red: 1.0, green: 0.2, blue: 0.2)  // Light red
                ]), startPoint: .top, endPoint: .bottom))
                .rotationEffect(.degrees(rotation))
                .hoverEffect(.highlight)
                .mask {
                    Capsule()
                        .stroke(lineWidth: 10)
                        .frame(width: 300, height: 60)
                }
                .hoverEffect { effect, isActive, proxy in
                    effect.scaleEffect(!isActive ? 1.0 : scaleEffect)
                }
            
            // Button
            NavigationButton(
                title: "Attack Cancer",
                action: {
                    Task {
                        if !appModel.isMainWindowOpen {
                            openWindow(id: AppModel.mainWindowId)
                            appModel.isMainWindowOpen = true
                        }
                        appModel.isInstructionsWindowOpen = true
                        await appModel.transitionToPhase(.playing, adcDataModel: dataModel)
                    }
                },
                font: .title,
                scaleEffect: 1.1,
                width: 250
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
//    AttackCancerViewerButton()
//}
