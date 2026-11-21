//
//  TourCoins.swift
//  ExpenseKu
//
//  Amber coins (welcome-tour.md §4.6): a few pop out of the wallet when a mission completes,
//  and a shower falls behind the chapter card. Reduce Motion drops both.
//

import SwiftUI

struct TourCoin: View {
    var size: CGFloat = 16

    var body: some View {
        Circle()
            .fill(Theme.accent)
            .overlay(Circle().inset(by: size * 0.2).stroke(Color(hex: 0xC47E1E), lineWidth: 1.5))
            .overlay(Circle().stroke(Theme.onAccent, lineWidth: 1.5))
            .frame(width: size, height: size)
    }
}

struct TourCoinBurst: View {
    let trigger: Int
    let origin: CGPoint

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private static let flights: [CGSize] = [
        CGSize(width: -46, height: -70), CGSize(width: -18, height: -96), CGSize(width: 14, height: -88),
        CGSize(width: 40, height: -64), CGSize(width: 0, height: -110),
    ]

    var body: some View {
        if !reduceMotion, trigger > 0 {
            ZStack {
                ForEach(Self.flights.enumerated(), id: \.offset) { index, flight in
                    TourCoin(size: 14)
                        .keyframeAnimator(initialValue: CoinFlight(), trigger: trigger) { coin, phase in
                            coin
                                .offset(x: phase.progress * flight.width,
                                        y: phase.progress * flight.height + phase.fall)
                                .opacity(phase.opacity)
                        } keyframes: { _ in
                            KeyframeTrack(\.progress) {
                                CubicKeyframe(0, duration: 0.01 + Double(index) * 0.04)
                                CubicKeyframe(1, duration: 0.35)
                            }
                            KeyframeTrack(\.fall) {
                                CubicKeyframe(0, duration: 0.36 + Double(index) * 0.04)
                                CubicKeyframe(70, duration: 0.45)
                            }
                            KeyframeTrack(\.opacity) {
                                CubicKeyframe(1, duration: 0.01)
                                CubicKeyframe(1, duration: 0.6 + Double(index) * 0.04)
                                CubicKeyframe(0, duration: 0.25)
                            }
                        }
                }
            }
            .position(origin)
            .allowsHitTesting(false)
        }
    }
}

private struct CoinFlight {
    var progress: CGFloat = 0
    var fall: CGFloat = 0
    var opacity: Double = 0
}

struct TourCoinShower: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if !reduceMotion {
            GeometryReader { proxy in
                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    ZStack {
                        ForEach(0..<14, id: \.self) { index in
                            let seed = Double(index) * 0.618
                            let speed = 90 + (seed.truncatingRemainder(dividingBy: 1)) * 80
                            let span = proxy.size.height + 40
                            let y = (time * speed + seed * span).truncatingRemainder(dividingBy: span) - 20
                            let x = (seed * 997).truncatingRemainder(dividingBy: 1) * proxy.size.width
                            TourCoin(size: 12 + CGFloat(index % 3) * 4)
                                .rotation3DEffect(.degrees(time * 160 + seed * 90), axis: (x: 0, y: 1, z: 0))
                                .position(x: x, y: y)
                        }
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}
