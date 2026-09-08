//
//  SpendByAccountChart.swift
//  ExpenseKu
//
//  Spend per account as proportion bars. Mirrors SpendByCategoryChart; the
//  "Unassigned" bucket (nil account) appears as its own row with the name-derived
//  tint, since it has no entity behind it to take a swatch from.
//

import SwiftUI

struct SpendByAccountChart: View {
    let data: [AccountSpend]

    @State private var growth = ChartGrowth()

    private var maxTotal: Double { max(data.map(\.total.doubleValue).max() ?? 1, 1) }

    var body: some View {
        VStack(spacing: 16) {
            ForEach(data) { item in
                ProportionRow(
                    name: item.accountName,
                    value: item.total,
                    fraction: item.total.doubleValue / maxTotal,
                    tint: Theme.categoryTint(hex: item.colorHex, seed: item.accountName),
                    symbol: item.symbol ?? Account.defaultSymbol,
                    growth: growth.factor
                )
            }
        }
        .growsOnAppear(growth, trigger: data.map(\.id))
    }
}
