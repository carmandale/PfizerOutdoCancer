import SwiftUI

struct ADCSelectorView: View {
    @Environment(AppModel.self) var appModel
    @Environment(ADCDataModel.self) var dataModel
    
    
    var body: some View {
        
        VStack (spacing:30) {
            HStack (spacing: 10) {
                Text("Select Antibody Color")
                    .font(.title)
                Spacer()
                
                Button {
                    print("ITR..Checkmark button pressed")
                    dataModel.adcBuildStep = 1
                    dataModel.selectedLinkerType = 0
                } label: {
                    Label("", systemImage: "checkmark.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 44))  // visionOS recommended size
                        .symbolRenderingMode(.hierarchical)
                }
                .frame(width: 60, height: 60)  // visionOS minimum tappable area
                .contentShape(Rectangle())
                .foregroundStyle(.green)
                .disabled(dataModel.selectedADCAntibody == nil)
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
                }
            }
            .padding(.bottom, 30)
        }
        .frame(width: 600, height: 300)
        .glassBackgroundEffect()
    }
}

//#Preview {
//    ADCSelectorView()
//        .environment(ADCAppModel())
//        .environment(ADCDataModel())
//    
//}
