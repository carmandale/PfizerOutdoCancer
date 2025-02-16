//
//  Twirl.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 1/9/25.
//
import SwiftUI

struct Appear: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        // We'll treat `.didDisappear` as the "disappearing" phase
        // and disable hit-testing at that time so it doesn't block taps.
        let isDisappearing = (phase == .didDisappear)
        
        return content
            .allowsHitTesting(!isDisappearing) // disable in removal phase
            .scaleEffect(phase.isIdentity ? 1 : 0.5)
            .opacity(phase.isIdentity ? 1 : 0)
            .blur(radius: phase.isIdentity ? 0 : 10)
            // For insertion phase: let’s flash brightness
            .brightness(phase == .willAppear ? 1 : 0)
    }
}


