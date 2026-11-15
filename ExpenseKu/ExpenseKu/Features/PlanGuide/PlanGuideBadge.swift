//
//  PlanGuideBadge.swift
//  ExpenseKu
//

import SwiftUI

struct PlanGuideBadge: View {
    var isProminent = false

    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 44

    var body: some View {
        Image(systemName: "book")
            .font(.dsBody)
            .foregroundStyle(isProminent ? Theme.accentText : Theme.textSecondary)
            .frame(width: size, height: size)
            .background(isProminent ? Theme.accent.opacity(0.18) : Theme.surface, in: .circle)
            .accessibilityHidden(true)
    }
}
