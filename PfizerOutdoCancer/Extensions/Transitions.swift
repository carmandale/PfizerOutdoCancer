//
//  Twirl.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 1/9/25.
//
import SwiftUI

struct Appear: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .scaleEffect(phase.isIdentity ? 1 : 0.5)
            .opacity(phase.isIdentity ? 1 : 0)
            .blur(radius: phase.isIdentity ? 0 : 10)
//            .rotationEffect(
//                .degrees(
//                    phase == .willAppear ? 360 :
//                        phase == .didDisappear ? -360 : .zero
//                )
//            )
            .brightness(phase == .willAppear ? 1 : 0)
    }
}


