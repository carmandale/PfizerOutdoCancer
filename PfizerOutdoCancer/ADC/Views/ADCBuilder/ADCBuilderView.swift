import SwiftUI

struct ADCBuilderView: View {
    @Environment(ADCAppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel
    @Environment(AppModel.self) private var dacAppModel
    
    
    let titles = ["Antibodies", "Linker", "Payload", "ADC Ready"]
    
    let descriptions = [
                        "\tFirst, the journey begins with creating monoclonal antibodies in cell cultures. These antibodies are like precision-guided missiles designed to seek out and bind to cancer cells. They are the key to ensuring that the treatment targets only the cancer cells, leaving healthy cells unharmed.",
                        "\tNext, a special chemical linker is attached to the antibodies. This linker acts as a smart bridge, ensuring that the powerful cancer-fighting drug is only released when the antibody reaches the cancer cell. This step is crucial for delivering the treatment directly to the cancer cells, minimizing side effects.",
                        "\tFinally, the cytotoxic drug, which is designed to kill cancer cells, is chemically linked to the antibodies through a process called conjugation. This creates the antibody-drug conjugate (ADC). The ADC is then purified and rigorously tested to ensure it is effective and safe. Once it passes all tests, it is formulated, sterilized, and packaged into vials or syringes.",
                        "\tWhen administered to patients, the ADC travels through the bloodstream, finds the cancer cells, and releases the drug to destroy them. This targeted approach helps to outdo cancer by attacking it directly while sparing healthy cells."
    ]
    
    
    var body: some View {
        VStack (spacing:30) {
            ZStack {
                HStack {
                    Image("Pfizer_Logo_White_RGB")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100)
                        .padding(.leading, 30)
                    Spacer()
                }
                HStack {
                    Spacer()
                    Text(appModel.immersiveSpaceState == .closed ? "ADC Builder" : titles[dataModel.adcBuildStep])
                        .font(.largeTitle)
                    Spacer()
                }
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 30)
            .background(.black.opacity(0.4))
            HStack (alignment: .top, spacing: 50){
                Group {
                    ADCButtonSquareWithOutline(imageName: dataModel.getADCImageName(),
                                            outlineColor: Color.white,
                                            description: "Antibody",
                                            index: 0,
                                            isSelected: {
                        false
                    }) {
                        print("ITR..Button 0 antibody pressed")
                    }
                    
                    ADCButtonSquareWithOutline(imageName: dataModel.getLinkerImageName(),
                                            outlineColor: Color.white,
                                            description: "Linkers",
                                            index: 1,
                                            isSelected: {
                        false
                    }) {
                        print("ITR..Button 1 linkers pressed")
                    }
                    
                    ADCButtonSquareWithOutline(imageName: dataModel.getPayloadImageName(),
                                            outlineColor: Color.white,
                                            description: "Payload",
                                            index: 2,
                                            isSelected: {
                        false
                    }) {
                        print("ITR..Button 2 payload pressed")
                    }
                }
                .disabled(appModel.immersiveSpaceState == .closed)
            }
            HStack {
                Text(appModel.immersiveSpaceState == .closed ? "We'll start building the ADC.\n\nTap into the `Start building` button." : descriptions[dataModel.adcBuildStep])
                    .font(.title3)
                    .multilineTextAlignment(appModel.immersiveSpaceState == .closed ? .center : .leading)
            }
            .padding(.horizontal,30)
            .padding(.top, 30)
            Spacer()
            HStack (spacing: 30) {
                Spacer()
                ADCStartImmersiveButton()
                if dataModel.adcBuildStep == 3 {
                    Button {
                        Task {
                            await dacAppModel.transitionToPhase(.playing)
                        }
                    } label: {
                        Text("Start Game")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 300, height: 50)
                            .background(Color(hex: 0x0000c9))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.bottom, 30)
        }
        .frame(width: 800, height: 600)
        .glassBackgroundEffect()
    }
}

#Preview {
    ADCBuilderView()
        .environment(ADCAppModel())
        .environment(ADCDataModel())
}