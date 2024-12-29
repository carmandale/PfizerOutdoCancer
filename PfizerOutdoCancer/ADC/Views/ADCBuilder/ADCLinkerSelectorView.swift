import SwiftUI

struct ADCLinkerSelectorView: View {
    @Environment(ADCAppModel.self) var appModel
    @Environment(ADCDataModel.self) var dataModel
    
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
                
                Button {
                    // Fill all remaining linkers with current selection
                    dataModel.fillAllLinkers()
                    // Advance to next step
                    dataModel.adcBuildStep = 2
                    dataModel.selectedPayloadType = 0
                } label: {
                    Label("", systemImage: "checkmark.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 44))
                        .symbolRenderingMode(.hierarchical)
                }
                .frame(width: 60, height: 60)
                .contentShape(Rectangle())
                .foregroundStyle(.green)
                .disabled(dataModel.selectedLinkerType == nil)
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
                }
            }
            .padding(.bottom, 30)
        }
        .frame(width: 600, height: 280)
        .glassBackgroundEffect()
    }
}
#Preview {
    ADCLinkerSelectorView()
        .environment(ADCAppModel())
        .environment(ADCDataModel())
}
