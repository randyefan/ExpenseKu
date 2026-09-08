//
//  DayGroupHeader.swift
//  ExpenseKu
//
//  A day ledger card's header: the day on the left, its total on the right, joined
//  by the app's dotted leader rule. The total stays secondary and monospaced — the
//  coral accent is reserved for actions and selected states.
//

import SwiftUI

struct DayGroupHeader: View {
    let title: String
    let total: Decimal

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.dsSubhead).bold()
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .layoutPriority(1)

            LeaderLine()

            Text(total.formattedIDR())
                .font(.dsSubhead)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(Theme.textSecondary)
                .layoutPriority(1)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: Metric.cardGap) {
        DayGroupHeader(title: "Thu, 6 August", total: 30_000)
        DayGroupHeader(title: "Sun, 2 August", total: 1_450_000)
    }
    .padding()
    .warmBackground()
}
