//
//  SpendByCategoryChart.swift
//  ExpenseKu
//
//  Horizontal bar chart of spend per category. Pure presentation — it's handed
//  already-aggregated data from SpendSummary.
//

import SwiftUI
import Charts

struct SpendByCategoryChart: View {
    let data: [CategorySpend]

    private var maxTotal: Double { data.map(\.total.doubleValue).max() ?? 0 }

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Amount", item.total.doubleValue),
                y: .value("Category", item.categoryName)
            )
            // Coral only highlights the biggest slice; the rest stay charcoal.
            // Meaning is never colour-only — every bar is labelled with its value.
            .foregroundStyle(item.total.doubleValue >= maxTotal ? Theme.accent : Theme.textSecondary.opacity(0.5))
            .cornerRadius(6)
            .annotation(position: .trailing, alignment: .leading) {
                Text(item.total.formattedIDR())
                    .font(.dsCaption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .chartLegend(.hidden)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisValueLabel()
                    .font(.dsSubhead)
                    .foregroundStyle(Theme.text)
            }
        }
        .frame(height: max(120, CGFloat(data.count) * 44))
    }
}
