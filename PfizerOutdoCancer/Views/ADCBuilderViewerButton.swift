//
//  ADCBuilderViewerButton.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 12/13/24.
//

import SwiftUI

struct ADCBuilderViewerButton: View {
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        Button {
            Task {
                await appModel.transitionToPhase(.building)
            }
        } label: {
            Text("ADC Builder")
                .font(.title)
                .fontWeight(.bold)
                .padding()
                .frame(minWidth: 200)
        }
        .padding()
        .glassBackgroundEffect()
    }
    
       

}

//#Preview {
//    ADCBuilderViewerButton()
//}
