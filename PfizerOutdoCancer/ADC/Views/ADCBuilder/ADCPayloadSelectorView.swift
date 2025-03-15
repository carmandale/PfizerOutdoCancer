import SwiftUI

struct ADCPayloadSelectorView: View {
    @Environment(AppModel.self) var appModel
    @Environment(ADCDataModel.self) var dataModel
    
    var noButton: Bool = true
    
    var body: some View {
        VStack (spacing:30) {
            HStack (spacing: 10) {
                Text("Select Payload color and place Payload")
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if dataModel.placedPayloadCount > 0 {
                    Text("\(dataModel.placedPayloadCount) of 4")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .frame(alignment: .trailing)
                }
                
                
                ADCCheckmarkButton(
                    action: {
                        appModel.playMenuSelectSound()
                        // Update step state and advance
                        dataModel.stepStates[2].checkmarkClicked = true
                        dataModel.adcBuildStep = 3
                    },
                    isEnabled: dataModel.selectedPayloadType != nil && dataModel.placedPayloadCount == 4
                )
                // .disabled(noButton)
                
                
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 30)
            .background(.black.opacity(0.4))
            HStack (alignment: .top, spacing: 20){
                ADCButtonSquareWithOutline(imageName: "payload0",
                                        outlineColor: Color.white,
                                        description: "",
                                        index: 0,
                                        isSelected: {
                                            dataModel.selectedPayloadType == 0
                                        }) {
                    print("ITR..Button 0 pressed")
                    dataModel.selectedPayloadType = 0
                    dataModel.stepStates[2].colorSelected = true
                    dataModel.stepStates[2].checkmarkClicked = false
                }
                ADCButtonSquareWithOutline(imageName: "payload1",
                                        outlineColor: Color.white,
                                        description: "",
                                        index: 1,
                                        isSelected: {
                                            dataModel.selectedPayloadType == 1
                                        }) {
                    print("ITR..Button 1 pressed")
                    dataModel.selectedPayloadType = 1
                    dataModel.stepStates[2].colorSelected = true
                    dataModel.stepStates[2].checkmarkClicked = false
                }
                ADCButtonSquareWithOutline(imageName: "payload2",
                                        outlineColor: Color.white,
                                        description: "",
                                        index: 2,
                                        isSelected: {
                                            dataModel.selectedPayloadType == 2
                                        }) {
                    print("ITR..Button 2 pressed")
                    dataModel.selectedPayloadType = 2
                    dataModel.stepStates[2].colorSelected = true
                    dataModel.stepStates[2].checkmarkClicked = false
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
//    ADCPayloadSelectorView()
//        .environment(ADCAppModel())
//        .environment(ADCDataModel())
//}
