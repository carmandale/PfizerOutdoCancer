import SwiftUI
import OSLog

struct ADCBuilderView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    let titles = ["Antibodies", "Linker", "Payload", "ADC Ready"]
    
    let descriptions = [
        "\tFirst, the journey begins with creating monoclonal antibodies in cell cultures. These antibodies are like precision-guided missiles designed to seek out and bind to cancer cells. They are the key to ensuring that the treatment targets only the cancer cells, leaving healthy cells unharmed.",
        "\tNext, a special chemical linker is attached to the antibodies. This linker acts as a smart bridge, ensuring that the powerful cancer-fighting drug is only released when the antibody reaches the cancer cell. This step is crucial for delivering the treatment directly to the cancer cells, minimizing side effects.",
        "\tFinally, the cytotoxic drug, which is designed to kill cancer cells, is chemically linked to the antibodies through a process called conjugation. This creates the antibody-drug conjugate (ADC). The ADC is then purified and rigorously tested to ensure it is effective and safe. Once it passes all tests, it is formulated, sterilized, and packaged into vials or syringes.",
        "\tWhen administered to patients, the ADC travels through the bloodstream, finds the cancer cells, and releases the drug to destroy them. This targeted approach helps to outdo cancer by attacking it directly while sparing healthy cells."
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
                
                Text(appModel.immersiveSpaceState == .closed ? "ADC Builder" : {
                    switch dataModel.adcBuildStep {
                    case 0:
                        return "Antibody"
                    case 1:
                        return "Antibody + Linker"
                    case 2:
                        return "Antibody + Linker + Payload"
                    default:
                        return "Your ADC is ready"
                    }
                }())
                    .font(.largeTitle)
            }
            .padding(30)
            .background(.black.opacity(0.4))
            .frame(width: 800)

            // Description text
            HStack {
                Text(appModel.immersiveSpaceState == .closed ? "We'll start building the ADC.\n\nTap into the `Start building` button." : descriptions[dataModel.adcBuildStep])
                    .font(.title3)
                    .multilineTextAlignment(appModel.immersiveSpaceState == .closed ? .center : .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 600)
            .padding(.horizontal, 30)
            .padding(.top, 30)
            .padding(.bottom, !dataModel.isVOPlaying ? 30 : 60)
            
            // Selector views or navigation button
            if !dataModel.isVOPlaying && dataModel.hasInitialVOCompleted {
                if dataModel.adcBuildStep < 3 {
                    Group {
                        switch dataModel.adcBuildStep {
                        case 0:
                            ADCSelectorView()
                        case 1:
                            ADCLinkerSelectorView()
                        case 2:
                            ADCPayloadSelectorView()
                        default:
                            EmptyView()
                        }
                    }
                    .frame(width: 600)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                    .transition(Appear())
                } else {  // adcBuildStep must be 3
                    // Navigation button for step 3
                    VStack {
                        NavigationButton(
                            title: "Attack Cancer",
                            action: {
                                Task {
                                    // Log final color summary before attack
                                    os_log(.debug, "ADC Final Color Summary (Attack Button Pressed):")
                                    os_log(.debug, "- Antibody Color: \(dataModel.selectedADCAntibody ?? -1)")
                                    os_log(.debug, "- Linker Color: \(dataModel.selectedLinkerType ?? -1)")
                                    os_log(.debug, "- Payload Color: \(dataModel.selectedPayloadType ?? -1)")
                                    
                                    appModel.hasBuiltADC = true

                                    if !appModel.isMainWindowOpen {
                                        openWindow(id: AppModel.mainWindowId)
                                        appModel.isMainWindowOpen = true
                                        appModel.isInstructionsWindowOpen = true
                                    }
                                    await dismissImmersiveSpace()
                                    await appModel.transitionToPhase(.playing, adcDataModel: dataModel)
                                }
                            },
                            font: .title,
                            scaleEffect: 1.06
                        )
                        .fontWeight(.bold)
                        .glassBackgroundEffect()
                        .hoverEffect(.highlight)
                        .hoverEffect { effect, isActive, proxy in
                            effect.scaleEffect(!isActive ? 1.0 : 1.05)
                        }
                    }
                    .frame(width: 600)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                    .transition(Appear())
                }
            }
        }
        .frame(width: 800)
        .frame(alignment: .top) // height: dataModel.isVOPlaying ? 350 : 700,
        .glassBackgroundEffect()
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: dataModel.isVOPlaying)
    }
}

//#Preview {
//    
//    ADCBuilderView()
//        .environment(AppModel())
//        .environment(ADCDataModel())
//}
