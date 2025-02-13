//
//  OutdoCancer.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 1/8/25.
//

import SwiftUI

struct OutdoCancer: View {
    @Binding var showTitle: Bool
    
    var body: some View {
        VStack {
            if showTitle {
                Group {
                    Text("Let's Outdo Cancer")
                        .onAppear { print("🔔 OutdoCancer: Title text appeared") }
                        .font(.extraLargeTitle)
                        .shadow(color: .black, radius: 10, x: 0, y: 0)
                }
                .id(showTitle)   // changing the id forces a new view when showTitle toggles
                .transition(WordByWordTransition(
                    totalDuration: 2.0,
                    elementDuration: 0.8,
                    extraBounce: 0.2
                ))
            }
        }
        .frame(width: 600, height: 200)
//        .glassBackgroundEffect()
    }
}

#Preview {
    @Previewable @State var isVisible: Bool = true
    
    return OutdoCancer(showTitle: $isVisible)
}

