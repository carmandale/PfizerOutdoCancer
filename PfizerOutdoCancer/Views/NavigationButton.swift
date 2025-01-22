//
//  NavigationButton.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 1/21/25.
//

import SwiftUI

struct NavigationButton: View {
    let title: String
    let action: () async -> Void
    var font: Font = .body
    var scaleEffect: CGFloat = 1.2
    var width: CGFloat? = nil
    
    var body: some View {
        Button {
            Task { await action() }
        } label: {
            Text(title)
                .font(font)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .frame(width: width)
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .hoverEffect { effect, isActive, proxy in
            effect.scaleEffect(!isActive ? 1.0 : scaleEffect)
        }
    }
}