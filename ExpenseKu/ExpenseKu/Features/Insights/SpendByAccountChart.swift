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

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Amount", item.total.doubleValue),
                y: .value("Account", item.accountName)
            )
            .foregroundStyle(by: .value("Account", item.accountName))
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
