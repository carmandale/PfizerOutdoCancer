//
//  ContentView.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 12/22/24.
//
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Hello, visionOS!")
            .toolbar {
                ToolbarItem(placement: .bottomOrnament) {
                    Button("Action", systemImage: "star") {
                        // Action code
                    }
                }
            }
    }
}
