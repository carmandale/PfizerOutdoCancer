//
//  Coaching 2.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 3/5/25.
//


import SwiftUI
import RiveRuntime

struct ADCcoaching: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel
    
    @State private var width: CGFloat = 400
    @State private var height: CGFloat = 400 / (600 / 320)
    @State private var firstLineOpacity: Double = 0
    @State private var secondThirdLineOpacity: Double = 0
    @State private var viewOpacity: Double = 0
    
    // Disable autoPlay so we can manually control when the animation begins
    @State private var riveViewModel = RiveViewModel(fileName: "pinch", autoPlay: false)
    
    // Keep track of the task so we can cancel it if the view disappears quickly
    @State private var animationTask: Task<Void, Never>? = nil
    
    /// Starts the sequence for both the Rive animation and the text animations.
    func startAnimationSequence() {
        // Immediately reset text opacities
        viewOpacity = 0
        firstLineOpacity = 0
        secondThirdLineOpacity = 0
        
        Logger.debug("\n\n🤝 Starting ADC Coaching Overlay Animation 🤝\n\n")
        
        // Reset and then start the specific timeline "coachingAnimation"
        riveViewModel.reset()
        riveViewModel.play(animationName: "coachingAnimation")
        
        // Animate the text appearance in stages
        Task {
            // Small delay to ensure the Rive view has reset
            try? await Task.sleep(for: .milliseconds(300))
            
            // Fade in the overall view and the first line of text
            withAnimation(.easeIn(duration: 0.5)) {
                viewOpacity = 1
                firstLineOpacity = 1
            }
            
            // Delay before showing the remaining text
            try? await Task.sleep(for: .milliseconds(2200))
            
            // Fade in the rest of the text
            withAnimation(.easeIn(duration: 0.25)) {
                secondThirdLineOpacity = 1
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                // Rive animation
                riveViewModel.view()
                    .frame(width: width, height: height)
                    .padding(.bottom, 20)
                
                Text("Look at the Linker or Payload")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(firstLineOpacity)
                
                Text("Pinch your thumb and finger together")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(secondThirdLineOpacity)
                
                Text("and drag the element to the ADC")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(secondThirdLineOpacity)
                    .padding(.bottom, 20)
                
                Text("release your fingers to let it place")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(secondThirdLineOpacity)
            }
            .padding(30)
            .frame(width: 600)
//            .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 20))
//            .background(
//                    Color.white
//                        .opacity(0.5)
//                        .cornerRadius(20)
//                )
            
            // Debug reset button for testing the animation restart
//            Button {
//                startAnimationSequence()
//            } label: {
//                Image(systemName: "arrow.clockwise.circle.fill")
//                    .font(.system(size: 30))
//                    .foregroundColor(.white.opacity(0.7))
//                    .padding(10)
//            }
//            .buttonStyle(.plain) // Remove the default bounding box styling
        }
        .opacity(viewOpacity)
        .allowsHitTesting(false)
        .onChange(of: dataModel.isCoachingOverlayPresent) { _, isReady in
            Logger.info("onChange: isCoachingOverlayPresent changed to \(isReady)")
            if isReady {
                startAnimationSequence()
            }
        }
    }
}

//#Preview {
//    ADCcoaching()
//}
