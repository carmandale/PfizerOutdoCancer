import SwiftUI
import OSLog

struct ADCBuilderView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    @FocusState private var isFocused: Bool

    @State private var opacity: Double = 0  // Add state for opacity


    let titles = ["Antibodies", "Linker", "Payload", "ADC Ready"]
    
    let descriptions = [
        "First, the journey begins with creating monoclonal antibodies in cell cultures. These antibodies are like precision-guided missiles designed to seek out and bind to cancer cells. They are the key to ensuring that the treatment targets only the cancer cells, leaving healthy cells unharmed.",
        "Next, a special chemical linker is attached to the antibodies. This linker acts as a smart bridge, ensuring that the powerful cancer-fighting drug is only released when the antibody reaches the cancer cell. This step is crucial for delivering the treatment directly to the cancer cells, minimizing side effects.",
        "Finally, the cytotoxic drug, which is designed to kill cancer cells, is chemically linked to the antibodies through a process called conjugation. This creates the antibody-drug conjugate (ADC). The ADC is then purified and rigorously tested to ensure it is effective and safe. Once it passes all tests, it is formulated, sterilized, and packaged into vials or syringes.",
        "When administered to patients, the ADC travels through the bloodstream, finds the cancer cells, and releases the drug to destroy them. This targeted approach helps to outdo cancer by attacking it directly while sparing healthy cells."
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with logo and title
            ZStack {
                HStack {
                        Image("Pfizer_Logo_White_RGB")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100)
                        Spacer()
                    }
                    
                    // The title/text area
                    switch dataModel.adcBuildStep {
                        case 0:
                            Text("Antibody")
                                .font(.largeTitle)
                                .transition(.opacity)
                        case 1:
                            // In step 1, only the "+ Linker" part glows.
                            HStack(spacing: 0) {
                                Text("Antibody ")
                                    .font(.largeTitle)
                                Text("+ Linker")
                                    .font(.largeTitle)
                                    .glowing(if: true, color: Color("LightGreen800")) // Always glowing in step 1.
                                    .transition(.opacity)
                            }
                        case 2:
                            // In step 2, only the "+ Payload" part glows.
                            HStack(spacing: 0) {
                                Text("Antibody + Linker ")
                                    .font(.largeTitle)
                                Text("+ Payload")
                                    .font(.largeTitle)
                                    .glowing(if: true, color: Color("LightGreen800")) // Always glowing in step 2.
                                    .transition(.opacity)
                            }
                        default:
                            Text("Your ADC is ready")
                                .font(.largeTitle)
                                .transition(.opacity)
                        }
                    
            }
            .padding(30)
            .background(.black.opacity(0.4))
            .frame(width: 800)

            // Description text and progress
            VStack(spacing: 0) {
                HStack {
                    Text(descriptions[dataModel.adcBuildStep])
                        .font(.title3)
                        .multilineTextAlignment(appModel.immersiveSpaceState == .closed ? .center : .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(width: 600)
                .padding(.horizontal, 30)
                .padding(.top, 30)
                .padding(.bottom, 12)
                
                if dataModel.isVOPlaying {
                    VOProgressBar(progress: dataModel.voiceOverProgress)
                        .frame(width: 600)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 8)
                }
            }
            .padding(.bottom, !dataModel.isVOPlaying ? 30 : 20)
            

                
            
            // Selector views or navigation button
            if !dataModel.isVOPlaying { // && dataModel.hasInitialVOCompleted
                        switch dataModel.adcBuildStep {
                        case 0:
                                ADCSelectorView()
                                    .opacity(dataModel.hasInitialVOCompleted ? 1 : 0)
                                    .opacity(dataModel.adcBuildStep == 0 ? 1 : 0)
                                    .allowsHitTesting(dataModel.adcBuildStep == 0 ? true : false)
                                    .transition(Appear())
                        case 1:
                            ADCLinkerSelectorView()
                                    .opacity(dataModel.adcBuildStep == 1 ? 1 : 0)
                                    .allowsHitTesting(dataModel.adcBuildStep == 1 ? true : false)
                                    .transition(Appear())
                        case 2:
                            ADCPayloadSelectorView()
                                    .opacity(dataModel.adcBuildStep == 2 ? 1 : 0)
                                    .allowsHitTesting(dataModel.adcBuildStep == 2 ? true : false)
                                    .transition(Appear())
                        default:
                            EmptyView()
                        }
                    }

            // Updated navigation chevrons
             if dataModel.adcBuildStep > 0 || dataModel.adcBuildStep < 3 {
                 HStack {
                     // Back Chevron
                     if dataModel.adcBuildStep > 0 && dataModel.adcBuildStep < 3 {
                         Button(action: {
                             withAnimation {
                                 // Back navigation is always manual (no VO)
                                 dataModel.manualStepTransition = true
                                 dataModel.adcBuildStep -= 1
                             }
                         }) {
                             Image(systemName: "chevron.left")
                                 .font(.largeTitle)
                                 .foregroundColor(.white)
                                 .hoverEffect { effect, isActive, proxy in
                                     effect.scaleEffect(!isActive ? 1.0 : AppModel.UIConstants.buttonExpandScale)
                                 }
                         }
                         .glassBackgroundEffect()
                         .opacity(dataModel.canMoveBack ? 1.0 : 0.1)
                         .disabled(!dataModel.canMoveBack)
                     }
                    
                     Spacer()
                    
                     // Forward Chevron
                     if dataModel.adcBuildStep < 3 && !dataModel.isVOPlaying {
                         Button(action: {
                             withAnimation {
                                 let nextStep = dataModel.adcBuildStep + 1
                                 
                                 // If this step is complete and next step's VO hasn't been played,
                                 // do a natural transition (will play VO)
                                 if dataModel.stepStates[dataModel.adcBuildStep].checkmarkClicked {
                                     if !dataModel.stepStates[nextStep].voPlayed {
                                         dataModel.manualStepTransition = false
                                     } else {
                                         // VO has been played, do manual transition
                                         dataModel.manualStepTransition = true
                                     }
                                     dataModel.adcBuildStep += 1
                                 }
                             }
                         }) {
                             Image(systemName: "chevron.right")
                                 .font(.largeTitle)
                                 .foregroundColor(.white)
                                 .hoverEffect { effect, isActive, proxy in
                                     effect.scaleEffect(!isActive ? 1.0 : AppModel.UIConstants.buttonExpandScale)
                                 }
                         }
                         .glassBackgroundEffect()
                         .opacity(dataModel.canMoveForward ? 1.0 : 0.1)
                         .disabled(!dataModel.canMoveForward)
                     }
                 }
                 .padding(20)
                 .zIndex(0)
             }
            
            if !dataModel.isVOPlaying && dataModel.adcBuildStep == 3 {
                NavigationButton(
                    title: "Attack Cancer",
                    action: {
                        Task {
                            // Log final color summary before attack
                            os_log(.debug, "ADC Final Color Summary (Attack Button Pressed):")
                            os_log(.debug, "- Antibody Color: \(dataModel.selectedADCAntibody ?? -1)")
                            os_log(.debug, "- Linker Color: \(dataModel.selectedLinkerType ?? -1)")
                            os_log(.debug, "- Payload Color: \(dataModel.selectedPayloadType ?? -1)")

                            appModel.playMenuSelect2Sound()
                            
                            appModel.hasBuiltADC = true
                            
                            if !appModel.isMainWindowOpen {
                                openWindow(id: AppModel.mainWindowId)
                                appModel.isMainWindowOpen = true
                                appModel.isInstructionsWindowOpen = true
                            }
                            await dismissImmersiveSpace()
                            await appModel.transitionToPhase(.playing, adcDataModel: dataModel)
                            dataModel.showMainView = false
                        }
                    },
                    font: .title,
                    scaleEffect: AppModel.UIConstants.buttonExpandScale,
                    width: 250
                )
                .fontWeight(.bold)
                // .padding(.top, 10)
                .padding(.bottom, 60)
                .contentShape(Capsule())
                .zIndex(1)
                .opacity(dataModel.adcBuildStep == 3 ? 1 : 0)
            }
        }
        .frame(width: 800)
        .frame(alignment: .top) // height: dataModel.isVOPlaying ? 350 : 700,
        .glassBackgroundEffect() // must have this for the background glass and rounded corners
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: dataModel.isVOPlaying)
        .opacity(opacity)
        .onChange(of: dataModel.showMainView) { _, newValue in
            withAnimation(.easeIn(duration: 1.0)) {
                opacity = newValue ? 1.0 : 0.0
            }
        }
    }
}

import SwiftUI

struct GlowingModifier: ViewModifier {
    /// When true, the glow effect is active.
    var isGlowing: Bool
    /// The glow color.
    var color: Color = .blue
    /// The base blur radius for the glow.
    var baseBlur: CGFloat = 20
    /// How much extra blur to add when the effect is at its peak.
    var blurVariation: CGFloat = 10
    /// How much blur to apply to the glowing copy.
    var glowBlur: CGFloat = 20
    /// How much to scale the glowing copy to emphasize the effect.
    var glowScale: CGFloat = 1.2
    /// The base opacity for the glow.
    var baseOpacity: Double = 0.0
    /// Additional opacity added at the peak of the pulsation.
    var opacityVariation: Double = 1.0
    /// The opacity (intensity) of the glow.
    var glowIntensity: Double = 1.0

    @State private var pulsate = false

    func body(content: Content) -> some View {
        ZStack {
            if isGlowing {
                // The glow copy behind the text.
                content
                    .foregroundColor(color)
//                    .scaleEffect(pulsate ? glowScale : 1.0)
//                    .blur(radius: pulsate ? baseBlur + blurVariation : baseBlur)
                    .blur(radius: glowBlur)
                    // Animate the opacity.
                    .opacity(pulsate ? baseOpacity + opacityVariation : baseOpacity)
                    // Use an additive blend so the glow intensifies without obscuring the text.
                    .blendMode(.plusLighter)
                    .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulsate)
                content
                    .foregroundColor(color)
//                    .scaleEffect(pulsate ? glowScale : 1.0)
//                    .blur(radius: pulsate ? baseBlur + blurVariation : baseBlur)
                    .blur(radius: glowBlur * 0.5)
                    // Animate the opacity.
                    .opacity(pulsate ? baseOpacity + opacityVariation : baseOpacity)
                    // Use an additive blend so the glow intensifies without obscuring the text.
                    .blendMode(.plusLighter)
                    .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulsate)
                content
                    .foregroundColor(color)
//                    .scaleEffect(pulsate ? glowScale : 1.0)
//                    .blur(radius: pulsate ? baseBlur + blurVariation : baseBlur)
                    .blur(radius: glowBlur).blur(radius: glowBlur * 0.1)
                    // Animate the opacity.
                    .opacity(pulsate ? baseOpacity + opacityVariation : baseOpacity)
                    // Use an additive blend so the glow intensifies without obscuring the text.
                    .blendMode(.plusLighter)
                    .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulsate)
            }
            // The original content on top.
            content
        }
        .onAppear {
            if isGlowing {
                pulsate = true
            }
        }
    }
}

extension View {
    /// Applies a glowing effect if the condition is true.
    func glowing(if condition: Bool, color: Color = .blue, glowBlur: CGFloat = 20, glowScale: CGFloat = 1.2, glowIntensity: Double = 1.0) -> some View {
        self.modifier(GlowingModifier(isGlowing: condition, color: color, glowBlur: glowBlur, glowScale: glowScale, glowIntensity: glowIntensity))
    }
}

extension View {
    /// A convenient helper to apply the glow effect conditionally.
    func glowing(if condition: Bool, color: Color = .blue) -> some View {
        self.modifier(GlowingModifier(isGlowing: condition, color: color))
    }
}

// MARK: - VOProgressBar
struct VOProgressBar: View {
    let progress: Double
    
    var body: some View {
        ProgressView(value: progress)
            .progressViewStyle(.linear)
            .tint(
                LinearGradient(
                    colors: [
                        Color("gradient600"),
                        Color("gradient200")
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 2)
    }
}
