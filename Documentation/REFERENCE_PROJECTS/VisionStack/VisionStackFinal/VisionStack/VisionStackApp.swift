//
//  VisionStackApp.swift
//  VisionStack
//
//  Created by Brian Advent on 23.03.24.
//

import SwiftUI

@main
struct VisionStackApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        ImmersiveSpace(id: "StackingSpace") {
            StackingView()
        }
        
    }
}
