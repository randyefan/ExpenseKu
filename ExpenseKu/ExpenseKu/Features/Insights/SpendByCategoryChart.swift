//
//  SpendByCategoryChart.swift
//  ExpenseKu
//
//  Spend per category as proportion bars. Pure presentation — it's handed
//  already-aggregated data from SpendSummary.
//
//  Each bar wears its own category's tint and glyph, the same ones that category's
//  icon wears in the expense list, so the chart and the list decode each other.
//

import SwiftUI

struct SpendByCategoryChart: View {
    let data: [CategorySpend]

    @State private var growth = ChartGrowth()

    private var maxTotal: Double { max(data.map(\.total.doubleValue).max() ?? 1, 1) }

    var body: some View {
        VStack(spacing: 16) {
            ForEach(data) { item in
                ProportionRow(
                    name: item.categoryName,
                    value: item.total,
                    fraction: item.total.doubleValue / maxTotal,
                    tint: Theme.categoryTint(hex: item.colorHex, seed: item.categoryName),
                    symbol: item.symbol ?? CategoryIcon.symbol(for: item.categoryName),
                    growth: growth.factor
                )
            }
        }
        .growsOnAppear(growth, trigger: data.map(\.id))
    }
}
