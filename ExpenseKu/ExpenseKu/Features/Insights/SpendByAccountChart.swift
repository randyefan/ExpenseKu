//
//  SpendByAccountChart.swift
//  ExpenseKu
//
//  Horizontal bar chart of spend per account. Pure presentation — it's handed
//  already-aggregated data from SpendSummary. Mirrors SpendByCategoryChart; the
//  "Unassigned" bucket (nil account) appears as its own bar.
//

import SwiftUI
import Charts

struct SpendByAccountChart: View {
    let data: [AccountSpend]

    private var maxTotal: Double { data.map(\.total.doubleValue).max() ?? 0 }

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Amount", item.total.doubleValue),
                y: .value("Account", item.accountName)
            )
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
