//
//  Motion.swift
//  ExpenseKu — DesignSystem
//
//  The app's single motion vocabulary (see .scratch/revamp2/spec.md). Call sites
//  pick a named role rather than authoring a curve, so the whole app accelerates
//  and settles the same way.
//
//  Every spatial move goes through `.motion(_:value:)` or `.motionTransition(_:)`,
//  which collapse to a cross-fade under Reduce Motion. That is why the check lives
//  here once instead of in each view.
//

import SwiftUI

enum Motion {
    /// Something the finger released: settles, never bounces.
    static let settle = Animation.spring(duration: 0.40, bounce: 0)

    /// A control that snaps home — toggles, chips, the lens pill.
    static let snap = Animation.spring(duration: 0.28, bounce: 0.22)

    /// Sheets and presentations.
    static let sheet = Animation.spring(duration: 0.34, bounce: 0.16)

    /// Press feedback. Below the threshold where it reads as an animation.
    static let press = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.14)

    /// A surface arriving for the first time.
    static let reveal = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.28)

    /// A figure counting to a new value.
    static let number = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.50)

    /// What every spatial animation becomes under Reduce Motion.
    static let reduced = Animation.easeOut(duration: 0.20)

    /// Stagger step for a reveal cascade, capped so a long list never crawls.
    static func stagger(_ index: Int, step: Double = 0.045, limit: Int = 8) -> Double {
        Double(min(index, limit)) * step
    }
}

private struct MotionAnimation<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? Motion.reduced : animation, value: value)
    }
}

private struct MotionTransition: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let transition: AnyTransition

    func body(content: Content) -> some View {
        content.transition(reduceMotion ? .opacity : transition)
    }
}

extension View {
    /// Animates changes to `value` with a named role, honouring Reduce Motion.
    func motion<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(MotionAnimation(animation: animation, value: value))
    }

    /// A transition that becomes a cross-fade under Reduce Motion.
    func motionTransition(_ transition: AnyTransition) -> some View {
        modifier(MotionTransition(transition: transition))
    }
}

extension AnyTransition {
    /// The house entrance: rise and fade, never scale from zero.
    static var rise: AnyTransition {
        .asymmetric(
            insertion: .offset(y: 10).combined(with: .opacity),
            removal: .opacity
        )
    }

    /// Content replaced by paging: leaves toward `edge`, the new page arrives from
    /// the opposite side, so the direction of travel matches the button pressed.
    static func page(towards edge: Edge) -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: edge == .leading ? .trailing : .leading)
                .combined(with: .opacity),
            removal: .move(edge: edge).combined(with: .opacity)
        )
    }
}
