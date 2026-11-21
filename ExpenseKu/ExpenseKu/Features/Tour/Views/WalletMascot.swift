//
//  WalletMascot.swift
//  ExpenseKu
//
//  The tour's guide (welcome-tour.md §4.6): five vector poses moved by SwiftUI. Pointing
//  faces right and is mirrored here rather than stored twice.
//

import SwiftUI

struct WalletMascot: View {
    let pose: WalletPose
    var mirrored = false
    var size: CGFloat = 84
    var shake = 0
    var hop = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Image(pose.imageName)
                .resizable()
                .scaledToFit()
                .scaleEffect(x: mirrored ? -1 : 1)
                .id(pose)
                .transition(.opacity)
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: 0.15), value: pose)
        .modifier(WalletSway(isOn: pose == .talking && !reduceMotion))
        .keyframeAnimator(initialValue: CGFloat.zero, trigger: reduceMotion ? 0 : shake) { content, x in
            content.offset(x: x)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(-7, duration: 0.07)
                CubicKeyframe(7, duration: 0.09)
                CubicKeyframe(-5, duration: 0.09)
                CubicKeyframe(4, duration: 0.08)
                CubicKeyframe(0, duration: 0.08)
            }
        }
        .keyframeAnimator(initialValue: WalletHop(), trigger: reduceMotion ? 0 : hop) { content, hop in
            content
                .scaleEffect(x: hop.stretch, y: 2 - hop.stretch, anchor: .bottom)
                .offset(y: hop.lift)
        } keyframes: { _ in
            KeyframeTrack(\.lift) {
                CubicKeyframe(-22, duration: 0.18)
                CubicKeyframe(0, duration: 0.18)
                CubicKeyframe(0, duration: 0.2)
            }
            KeyframeTrack(\.stretch) {
                CubicKeyframe(0.94, duration: 0.18)
                CubicKeyframe(1, duration: 0.16)
                CubicKeyframe(1.12, duration: 0.08)
                SpringKeyframe(1, duration: 0.2)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text(appLocalized: pose.accessibilityLabel))
    }
}

private struct WalletHop {
    var lift: CGFloat = 0
    var stretch: CGFloat = 1
}

private struct WalletSway: ViewModifier {
    let isOn: Bool

    func body(content: Content) -> some View {
        if isOn {
            content.phaseAnimator([-3.0, 3.0]) { view, angle in
                view.rotationEffect(.degrees(angle), anchor: .bottom)
            } animation: { _ in .easeInOut(duration: 0.45) }
        } else {
            content
        }
    }
}
