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
                
                
                ADCCheckmarkButton(
                    action: {
                        print("ITR..Checkmark button pressed")
                        dataModel.adcBuildStep = 1
                            // dataModel.selectedLinkerType = 0
                    },
                    isEnabled: dataModel.selectedADCAntibody != nil
                )
                
                
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
                        // Task {
                        //     try? await Task.sleep(for: .milliseconds(1000))
                        //     dataModel.adcBuildStep = 1
                        // }
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
                        // Task {
                        //     try? await Task.sleep(for: .milliseconds(1000))
                        //     dataModel.adcBuildStep = 1
                        // }
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
                        // Task {
                        //     try? await Task.sleep(for: .milliseconds(1000))
                        //     dataModel.adcBuildStep = 1
                        // }
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
