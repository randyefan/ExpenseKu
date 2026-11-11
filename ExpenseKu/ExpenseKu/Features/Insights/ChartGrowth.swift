//
//  ChartGrowth.swift
//  ExpenseKu
//
//  Drives the 0→1 factor every Insights chart multiplies its values by, so bars
//  grow out of the axis when the card first appears and again whenever the period
//  filter changes the data underneath them.
//
//  The scale domain is pinned to the real maximum at the call site, so growing is
//  the bars rising into a fixed frame rather than the axis rescaling around them.
//  Under Reduce Motion the factor starts at 1 and nothing moves.
//

import SwiftUI

@Observable
@MainActor
final class ChartGrowth {
    private(set) var factor: Double = 0
    @ObservationIgnored private var grownFor: AnyHashable?

    func appear(with trigger: AnyHashable, reduceMotion: Bool) {
        grownFor = trigger
        grow(reduceMotion: reduceMotion)
    }

    func regrow(for trigger: AnyHashable, reduceMotion: Bool, delay: Double = 0.05) async {
        guard trigger != grownFor else { return }
        grownFor = trigger
        guard !reduceMotion else {
            factor = 1
            return
        }
        factor = 0
        try? await Task.sleep(for: .seconds(delay))
        guard !Task.isCancelled else { return }
        grow(reduceMotion: false)
    }

    private func grow(reduceMotion: Bool) {
        guard factor < 1 else { return }
        if reduceMotion {
            factor = 1
        } else {
            withAnimation(Motion.chartGrow) { factor = 1 }
        }
    }
}

private struct GrowsOnAppear: ViewModifier {
    let growth: ChartGrowth
    let trigger: AnyHashable

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .onAppear { growth.appear(with: trigger, reduceMotion: reduceMotion) }
            .task(id: trigger) {
                await growth.regrow(for: trigger, reduceMotion: reduceMotion)
            }
    }
}

extension View {
    /// Grows `growth` as soon as the view appears, and again whenever `trigger` changes.
    func growsOnAppear(_ growth: ChartGrowth, trigger: some Hashable) -> some View {
        modifier(GrowsOnAppear(growth: growth, trigger: AnyHashable(trigger)))
    }
}
