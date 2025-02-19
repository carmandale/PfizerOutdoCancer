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
            ZStack {
                // Invisible placeholder text to maintain consistent layout
                Text("Let's Outdo Cancer")
                    .font(.extraLargeTitle)
                    .opacity(0)
                
                if showTitle {
                    AnimatedText()
                }
            }
            .padding()
            .frame(width: 600, height: 200)
        }
        
    }
}

struct AnimatedText: View {
    var body: some View {
        Text("Let's Outdo Cancer")
            .font(.extraLargeTitle)
            .transition(WordByWordTransition(
                totalDuration: 2.0,
                elementDuration: 0.8,
                extraBounce: 0.2
            ))
    }
}
