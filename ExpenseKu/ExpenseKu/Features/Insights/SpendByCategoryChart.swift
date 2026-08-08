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

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Amount", item.total.doubleValue),
                y: .value("Category", item.categoryName)
            )
            .foregroundStyle(by: .value("Category", item.categoryName))
            .annotation(position: .trailing, alignment: .leading) {
                Text(item.total.formattedIDR())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .chartLegend(.hidden)
        .chartXAxis(.hidden)
        .frame(height: max(120, CGFloat(data.count) * 44))
    }
}
