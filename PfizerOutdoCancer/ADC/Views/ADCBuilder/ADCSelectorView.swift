import SwiftUI

struct ADCSelectorView: View {
    @Environment(AppModel.self) var appModel
    @Environment(ADCDataModel.self) var dataModel
    
    var noButton: Bool = false
    
    var body: some View {
        VStack (spacing:30) {
            HStack (spacing: 10) {
                Text("Select Antibody Color")
                    .font(.title)
                Spacer()
                
                
                ADCCheckmarkButton(
                    action: {
                        appModel.playMenuSelectSound()
                        // Update step state and advance
                        dataModel.stepStates[0].checkmarkClicked = true
                        dataModel.adcBuildStep = 1
                    },
                    isEnabled: dataModel.selectedADCAntibody != nil
                )
                .disabled(noButton)
                
                
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 30)
            .background(.black.opacity(0.4))
            HStack (alignment: .top, spacing: 20){
                    ADCButtonSquareWithOutline(imageName: "antibody0",
                                           outlineColor: Color.white,
                                           description: "",
                                           index: 0,
                                           isSelected: {
                        dataModel.selectedADCAntibody == 0
                    }) {
                        print("ITR..Button 0 antibody pressed")
                        dataModel.selectedADCAntibody = 0
                        dataModel.stepStates[0].colorSelected = true
                        dataModel.stepStates[0].checkmarkClicked = false
                    }
                    ADCButtonSquareWithOutline(imageName: "antibody1",
                                           outlineColor: Color.white,
                                           description: "",
                                           index: 1,
                                           isSelected: {
                        dataModel.selectedADCAntibody == 1
                    }) {
                        print("ITR..Button 1 antibody pressed")
                        dataModel.selectedADCAntibody = 1
                        dataModel.stepStates[0].colorSelected = true
                        dataModel.stepStates[0].checkmarkClicked = false
                    }
                    ADCButtonSquareWithOutline(imageName: "antibody2",
                                           outlineColor: Color.white,
                                           description: "",
                                           index: 2,
                                           isSelected: {
                        dataModel.selectedADCAntibody == 2
                    }) {
                        print("ITR..Button 2 antibody pressed")
                        dataModel.selectedADCAntibody = 2
                        dataModel.stepStates[0].colorSelected = true
                        dataModel.stepStates[0].checkmarkClicked = false
                    }
                }
                .padding(.bottom, 30)
            }
        .frame(width: 600, height: 300)
        .glassBackgroundEffect()
        // .selectorAnimation(isVOPlaying: dataModel.isVOPlaying)
    }
}

//#Preview {
//    ADCSelectorView()
//        .environment(AppModel())
//        .environment(ADCDataModel())
//    
//}
