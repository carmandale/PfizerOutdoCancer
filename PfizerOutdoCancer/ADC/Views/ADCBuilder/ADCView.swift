import SwiftUI

struct ADCView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel
    
    var body: some View {
        VStack {
            Image("tap")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
            Text("Tap to select your ADC colors")
                .font(.title)
                .foregroundColor(.white)
            Text("Tap and drag the linkers and payloads to the Antibody")
                .font(.title)
                .foregroundColor(.white)
            ADCStartImmersiveButton()
        }
        .frame(width: 800, height: 600)
        .glassBackgroundEffect()
    }
}

//#Preview {
//    ADCView()
//        .environment(ADCAppModel())
//        .environment(ADCDataModel())
//}
