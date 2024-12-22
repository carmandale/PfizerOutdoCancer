import SwiftUI

struct ADCPayloadSelectorView: View {
    @Environment(ADCAppModel.self) var appModel
    @Environment(ADCDataModel.self) var dataModel
    
    var body: some View {
        VStack (spacing:30) {
            HStack (spacing: 10) {
                Text("Select Payload")
                    .font(.title)
                Spacer()
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 30)
            .background(.black.opacity(0.4))
            HStack (alignment: .top, spacing: 20){
                ADCButtonSquareWithOutline(imageName: "payload0", outlineColor: Color.white, description: "", index: 0, isSelected: {
                    dataModel.selectedPayloadType == 0
                }) {
                    print("ITR..Button 0 pressed")
                    dataModel.selectedPayloadType = 0
                }
                ADCButtonSquareWithOutline(imageName: "payload1", outlineColor: Color.white, description: "", index: 1, isSelected: {
                    dataModel.selectedPayloadType == 1
                }) {
                    print("ITR..Button 1 pressed")
                    dataModel.selectedPayloadType = 1
                }
                ADCButtonSquareWithOutline(imageName: "payload2", outlineColor: Color.white, description: "", index: 2, isSelected: {
                    dataModel.selectedPayloadType == 2
                }) {
                    print("ITR..Button 2 pressed")
                    dataModel.selectedPayloadType = 2
                }
                
            }
            .padding(.bottom, 30)
        }
        .frame(width: 600, height: 280)
        .glassBackgroundEffect()
    }
}

#Preview {
    ADCPayloadSelectorView()
        .environment(ADCAppModel())
        .environment(ADCDataModel())
}
