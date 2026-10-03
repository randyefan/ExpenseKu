//
//  PlanFilterPill.swift
//  ExpenseKu
//
//  What says a plan filter is on once the legend that set it has scrolled away
//  (plan-filter.md §4.5). It floats above the tab bar in the same glass, so the two read
//  as one layer; the whole pill is one button that clears the filter.
//

import SwiftUI

extension PlanFilter {
    var tint: Color {
        switch self {
        case .outsidePlan: Theme.accent
        case .fromPlan: Theme.plan
        }
    }
}

struct PlanFilterPill: View {
    let filter: PlanFilter
    let onClear: () -> Void

    var body: some View {
        Button(action: onClear) {
            HStack(spacing: 10) {
                Circle()
                    .fill(filter.tint)
                    .frame(width: 8, height: 8)
                Text(filter.pillTitle)
                    .font(.dsSubhead).fontWeight(.semibold)
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                Image(systemName: "xmark")
                    .font(.dsCaption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 24, height: 24)
                    .background(Theme.textSecondary.opacity(0.18), in: .circle)
            }
            .padding(.leading, 14)
            .padding(.trailing, 6)
            .padding(.vertical, 6)
            .contentShape(.capsule)
            .glassEffect(.regular.interactive(), in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Clear filter")
        .accessibilityValue(filter.pillTitle)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack(spacing: 12) {
        PlanFilterPill(filter: .outsidePlan, onClear: {})
        PlanFilterPill(filter: .fromPlan, onClear: {})
    }
    .padding()
    .appBackground()
}
