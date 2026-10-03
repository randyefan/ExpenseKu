//
//  SpendingSplitBar.swift
//  ExpenseKu
//
//  The split as one capsule: Outside plan in the accent, From plan in violet.
//

import SwiftUI

struct SpendingSplitBar: View {
    let split: SpendingSplit

    var body: some View {
        GeometryReader { proxy in
            let hasOutside = split.outsidePlan > 0
            let gap: CGFloat = hasOutside && split.fromPlan > 0 ? 2 : 0
            let outsideWidth = hasOutside
                ? max(4, (proxy.size.width - gap) * split.outsideFraction)
                : 0
            HStack(spacing: gap) {
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: outsideWidth)
                Rectangle()
                    .fill(Theme.plan)
            }
        }
        .frame(height: 8)
        .clipShape(.capsule)
        .motion(Motion.number, value: split)
        .accessibilityHidden(true)
    }
}
