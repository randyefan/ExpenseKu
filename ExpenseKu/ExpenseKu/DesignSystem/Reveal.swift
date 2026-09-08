//
//  Reveal.swift
//  ExpenseKu — DesignSystem
//
//  A staggered first-paint entrance. Applied to the handful of blocks a screen is
//  built from, never to every row of a long list: the cascade is there to explain
//  the screen's structure once, not to decorate scrolling.
//
//  `trigger` re-runs the cascade when the screen's subject changes — paging to
//  another cycle, or switching the Insights period. Under Reduce Motion the whole
//  thing collapses to "already visible".
//
//  A dense field of small cells (the appearance picker's swatches and glyphs) is
//  the one exception to "not every row": there the cascade reads as the palette
//  dealing itself out, so `step`/`limit` open up to let a fast sweep cross all of
//  them inside the same overall duration a few big blocks would take.
//

import SwiftUI

private struct Reveal: ViewModifier {
    let index: Int
    let step: Double
    let limit: Int
    let trigger: AnyHashable

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 10)
            .task(id: trigger) {
                guard !reduceMotion else {
                    shown = true
                    return
                }
                shown = false
                try? await Task.sleep(for: .seconds(Motion.stagger(index, step: step, limit: limit)))
                guard !Task.isCancelled else { return }
                withAnimation(Motion.reveal) { shown = true }
            }
    }
}

extension View {
    /// Fades and rises this block into place, `index` steps after the first one.
    func reveal(_ index: Int, step: Double = 0.045, limit: Int = 8,
                trigger: some Hashable = 0) -> some View {
        modifier(Reveal(index: index, step: step, limit: limit, trigger: AnyHashable(trigger)))
    }
}
