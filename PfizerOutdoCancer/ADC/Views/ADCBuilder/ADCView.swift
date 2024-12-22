import SwiftUI

struct ADCView: View {
    @Environment(ADCAppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel
    
    var body: some View {
        VStack {
            ADCStartImmersiveButton()
        }
        .frame(width: 800, height: 600)
        .glassBackgroundEffect()
    }
}

#Preview {
    ADCView()
        .environment(ADCAppModel())
        .environment(ADCDataModel())
}
