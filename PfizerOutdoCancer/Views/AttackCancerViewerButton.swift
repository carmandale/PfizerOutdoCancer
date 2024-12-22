//
//  AttackCancerViewerButton.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 12/13/24.
//

import SwiftUI

struct AttackCancerViewerButton: View {
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        Button {
            Task {
                await appModel.transitionToPhase(.playing)
            }
        } label: {
            Text("Attack Cancer")
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
//    AttackCancerViewerButton()
//}
