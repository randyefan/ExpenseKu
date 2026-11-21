//
//  TourRings.swift
//  ExpenseKu
//

import SwiftUI

struct TourTargetRing: View {
    let hole: TourHole
    var pulses: Bool
    var nudges: Int
    var dashed = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: hole.radius)
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 2.5, dash: dashed ? [6, 5] : []))
            if pulses && !reduceMotion {
                RoundedRectangle(cornerRadius: hole.radius)
                    .stroke(Theme.accent.opacity(0.6), lineWidth: 2)
                    .phaseAnimator([false, true]) { ring, expanded in
                        ring
                            .scaleEffect(expanded ? 1.12 : 1)
                            .opacity(expanded ? 0 : 0.9)
                    } animation: { expanded in
                        expanded ? .easeOut(duration: 1.1) : .linear(duration: 0.01)
                    }
            }
        }
        .keyframeAnimator(initialValue: CGFloat(1), trigger: reduceMotion ? 0 : nudges) { ring, scale in
            ring.scaleEffect(scale)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(1.08, duration: 0.14)
                CubicKeyframe(1, duration: 0.14)
                CubicKeyframe(1.08, duration: 0.14)
                CubicKeyframe(1, duration: 0.14)
            }
        }
        .frame(width: hole.rect.width, height: hole.rect.height)
        .position(x: hole.rect.midX, y: hole.rect.midY)
        .allowsHitTesting(false)
    }
}

struct TourTouchRing: View {
    let touch: TourTouch

    @State private var spread = false

    var body: some View {
        Circle()
            .stroke(Theme.accent, lineWidth: 2)
            .frame(width: 44, height: 44)
            .scaleEffect(spread ? 1.4 : 0.6)
            .opacity(spread ? 0 : 1)
            .position(touch.point)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeOut(duration: 0.7)) { spread = true }
            }
            .id(touch.id)
    }
}
