//
//  PersonSpendHeader.swift
//  ExpenseKu
//
//  The header card of a companion's drill-down: avatar, name, the total credited to
//  them, and how many expenses over which period.
//

import SwiftUI

struct PersonSpendHeader: View {
    let name: String
    let total: Decimal
    let count: Int
    let rangeLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                PersonAvatar(name: name, size: Metric.iconSize)
                Text(name)
                    .font(.dsTitle).bold()
                    .foregroundStyle(Theme.text)
            }

            MoneyText(total, font: .dsHero, color: Theme.text)

            Text("^[\(count) expense](inflect: true) · \(rangeLabel)")
                .font(.dsSubhead)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

#Preview {
    VStack(spacing: Metric.cardGap) {
        PersonSpendHeader(name: "Tarisa", total: 1_250_000, count: 12, rangeLabel: "All time")
        PersonSpendHeader(name: "Budi", total: 0, count: 0, rangeLabel: "This month")
    }
    .padding()
    .warmBackground()
}
