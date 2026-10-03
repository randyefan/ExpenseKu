//
//  SpendingSplitView.swift
//  ExpenseKu
//
//  The Outside plan / From plan split: the bar and its two-chip legend, each chip the
//  switch that filters to its half (plan-filter.md §4.1). Drawn by the cycle header, by
//  Insights' SPENDING card and by a drill-in's split card.
//

import SwiftUI

struct SpendingSplitView: View {
    let split: SpendingSplit
    let filter: PlanFilter?
    let onTap: (PlanFilter) -> Void

    var body: some View {
        VStack(spacing: 10) {
            SpendingSplitBar(split: split)

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top) {
                    chip(.outsidePlan, alignment: .leading)
                    Spacer(minLength: 12)
                    chip(.fromPlan, alignment: .trailing)
                }
                VStack(alignment: .leading, spacing: 8) {
                    chip(.outsidePlan, alignment: .leading)
                    chip(.fromPlan, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func chip(_ half: PlanFilter, alignment: HorizontalAlignment) -> some View {
        SpendingSplitChip(
            half: half,
            amount: half == .outsidePlan ? split.outsidePlan : split.fromPlan,
            isLit: filter == half,
            alignment: alignment
        ) {
            onTap(half)
        }
    }
}
