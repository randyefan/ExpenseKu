//
//  FilterPill.swift
//  ExpenseKu
//
//  What says this filter is on once the screen has scrolled (docs/prd/expense-filter.md
//  §4.4). PlanFilterPill's glass and shape, so the two stack as one layer, with a filter
//  glyph where that pill has its dot; the whole pill is one button that clears this filter.
//

import SwiftUI

struct FilterPill: View {
    let text: String
    let onClear: () -> Void

    var body: some View {
        Button(action: onClear) {
            HStack(spacing: 10) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.dsCaption.weight(.bold))
                    .foregroundStyle(Theme.accent)
                Text(text)
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
        .padding(.horizontal, Metric.screenPadding)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Clear filters")
        .accessibilityValue(text)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack(spacing: 10) {
        FilterPill(text: "Category · Makan, Kopi", onClear: {})
        PlanFilterPill(filter: .outsidePlan, onClear: {})
    }
    .padding()
    .appBackground()
}
