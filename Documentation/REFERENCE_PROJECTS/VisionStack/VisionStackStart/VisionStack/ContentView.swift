//
//  ContentView.swift
//  VisionStack
//
//  Created by Brian Advent on 23.03.24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {


    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    @State var showImmersiveSpace = false
    
    var body: some View {
        GeometryReader { proxy in
            let textWidth = min(max(proxy.size.width * 0.4, 300), 500)
            ZStack {
                HStack(spacing: 60) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Vision Stack Pro")
                            .font(.system(size: 50, weight: .bold))
                            .padding(.bottom, 15)

                        Text("To start stacking cubes, click on the 'Start Stacking' button. Point with your left index finger where you want a cube to spawn. Make a pinching gesture with your right hand to drop a cube.\n\n You can place the cubes on tables and other surfaces, and also interact with them using your hands.")
                            .padding(.bottom, 30)
                            .accessibilitySortPriority(3)

                        Toggle(showImmersiveSpace ? "Stop Stacking" : "Start Stacking", isOn: $showImmersiveSpace).onChange(of:showImmersiveSpace) { _, isShowing in
                            // open Immersive Space
                            
                        }
                            .toggleStyle(.button)
                        
                        
                        
                    }
                    .frame(width: textWidth, alignment: .leading)

                    Color.clear
                        .overlay {
                            SampleModel(orientation: [-0.3,0.4,0])
                                .dragRotation(yawLimit: .degrees(45), pitchLimit: .degrees(45))
                                .frame(height: 200)
                                .frame(depth: 200)
                                .offset(z: 250)
                        }
                    
                    
                }
                .offset(y: -30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(70)
        
    }
}

