//
//  StackingView.swift
//  VisionStack
//
//  Created by Brian Advent on 23.03.24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct StackingView: View {
    @StateObject var model = HandTrackingViewModel()
    
    var body: some View {
        RealityView { content in
            content.add(model.setupContentEntity())
        }.task {
            await model.runSession()
        }.task {
            await model.processHandUpdates()
        }.task {
            await model.processReconstructionUpdates()
        }.gesture(SpatialTapGesture().targetedToAnyEntity().onEnded({ value in
            
            Task {
                await model.placeCube()
            }
            
            
        }))
    }
}

#Preview {
    StackingView()
}
