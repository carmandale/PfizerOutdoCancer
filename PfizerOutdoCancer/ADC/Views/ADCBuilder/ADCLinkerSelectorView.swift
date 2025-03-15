import SwiftUI

struct ADCLinkerSelectorView: View {
    @Environment(AppModel.self) var appModel
    @Environment(ADCDataModel.self) var dataModel
    
    var noButton: Bool = true
    
    var body: some View {
        VStack (spacing:30) {
            HStack(spacing: 10) {
                Text("Select Linker color and place Linker")
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if dataModel.placedLinkerCount > 0 {
                    Text("\(dataModel.placedLinkerCount) of 4")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .frame(alignment: .trailing)
                }
                
                
                ADCCheckmarkButton(
                    action: {
                        appModel.playMenuSelectSound()
                        // Update step state and advance
                        dataModel.stepStates[1].checkmarkClicked = true
                        dataModel.adcBuildStep = 2
                    },
                    isEnabled: dataModel.selectedLinkerType != nil && dataModel.placedLinkerCount == 4
                )
                // .disabled(noButton)
                
                
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 30)
            .background(.black.opacity(0.4))
            HStack (alignment: .top, spacing: 20){
                    ADCButtonSquareWithOutline(imageName: "linkers0",
                                            outlineColor: Color.white,
                                            description: "",
                                            index: 0,
                                            isSelected: {
                        dataModel.selectedLinkerType == 0
                    }) {
                        print("ITR..Button 0 pressed")
                        dataModel.selectedLinkerType = 0
                        dataModel.stepStates[1].colorSelected = true
                        dataModel.stepStates[1].checkmarkClicked = false
                    }
                    ADCButtonSquareWithOutline(imageName: "linkers1",
                                            outlineColor: Color.white,
                                            description: "",
                                            index: 1,
                                            isSelected: {
                        dataModel.selectedLinkerType == 1
                    }) {
                        print("ITR..Button 1 pressed")
                        dataModel.selectedLinkerType = 1
                        dataModel.stepStates[1].colorSelected = true
                        dataModel.stepStates[1].checkmarkClicked = false
                    }
                    ADCButtonSquareWithOutline(imageName: "linkers2",
                                            outlineColor: Color.white,
                                            description: "",
                                            index: 2,
                                            isSelected: {
                        dataModel.selectedLinkerType == 2
                    }) {
                        print("ITR..Button 2 pressed")
                        dataModel.selectedLinkerType = 2
                        dataModel.stepStates[1].colorSelected = true
                        dataModel.stepStates[1].checkmarkClicked = false
                    }
                }
                .padding(.bottom, 30)
            }
        .frame(width: 600, height: 280)
        .glassBackgroundEffect()
        // .selectorAnimation(isVOPlaying: dataModel.isVOPlaying)
    }
}
//#Preview {
//    ADCLinkerSelectorView()
//        .environment(ADCAppModel())
//        .environment(ADCDataModel())
//}
