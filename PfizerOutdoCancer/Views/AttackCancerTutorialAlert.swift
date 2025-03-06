//
//  AttackCancerViewerButton.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 12/13/24.
//

import SwiftUI

struct AttackCancerTutorialAlert: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel
    @Environment(\.openWindow) private var openWindow
    @State private var rotation: CGFloat = 0.0
    @State private var currentTheme: GradientTheme = .lightBlue
    @State private var emojiOpacity: Double = 1.0 // For emoji fading animation
    var scaleEffect: CGFloat = 1.2
    var width: CGFloat = 300
    var gradientWidth: CGFloat = 500
    var gradientHeight: CGFloat = 400
    var tutorialText: String = "⚠️ ADC Demonstration ⚠️"
    
    
    private func cycleTheme() {
        guard let currentIndex = GradientTheme.allCases.firstIndex(of: currentTheme) else { return }
        let nextIndex = (currentIndex + 1) % GradientTheme.allCases.count
        currentTheme = GradientTheme.allCases[nextIndex]
    }
    
    var body: some View {
        ZStack {
            // Outer gradient border with soft edge
            Capsule()
                .frame(width: gradientWidth, height: gradientHeight)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: currentTheme.colors),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .rotationEffect(.degrees(rotation))
                .mask {
                    Capsule()
                        .stroke(lineWidth: 20)
                        .frame(width: width, height: 60)
                        .blur(radius: 10)
                }
            
            // Inner gradient border (sharp)
            Capsule()
                .frame(width: gradientWidth, height: gradientHeight)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: currentTheme.colors),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .rotationEffect(.degrees(rotation))
                .mask {
                    Capsule()
                        .stroke(lineWidth: 10)
                        .frame(width: width, height: 60)
                }
            
            // The text label and background - matching button content
            HStack(spacing: 8) {
                // Left emoji with fading
                Text("⚠️")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .opacity(emojiOpacity)
                
                // Main text (stays at full opacity)
                Text("ADC Demonstration")
                    .font(.title3)
                    .fontWeight(.heavy)
                
                // Right emoji with fading
                Text("⚠️")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .opacity(emojiOpacity)
            }
            .padding(.horizontal, AppModel.UIConstants.buttonPaddingHorizontal)
            .padding(.vertical, AppModel.UIConstants.buttonPaddingVertical)
            .frame(width: width, height: 60)
            .background {
                RoundedRectangle(
                    cornerRadius: AppModel.UIConstants.buttonCornerRadius,
                    style: .continuous
                )
                .fill(Color("gradient600"))
            }
            .glassBackgroundEffect()
        }
        // Use drawingGroup to render the entire view hierarchy as a single image
        // This ensures that it fades as a unified element
        .drawingGroup()
        .onAppear {
            withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            
            // Emoji fading animation
            withAnimation(
                .easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
            ) {
                emojiOpacity = 0.1
            }
        }
        .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    }
}

//#Preview {
//    AttackCancerViewerButton()
//}
