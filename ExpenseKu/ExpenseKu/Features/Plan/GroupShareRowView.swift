//
//  GroupShareRowView.swift
//  ExpenseKu
//
//  One row of the plan's percentage table: a Group, its share of Total income, and the
//  amount (PRD §6.1.5).
//
//  Planned figures only (decision 16). This is the owner's allocation check — "Lovely
//  Support was 53,91% of income in March" — not a report on what was actually spent.
//

import SwiftUI

struct GroupShareRowView: View {
    let share: GroupShare

    var body: some View {
        HStack(spacing: 10) {
            if let symbol = share.symbol {
                Image(systemName: symbol)
                    .font(.dsCaption.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 16)
            }

            Text(share.groupName)
                .font(.dsSubhead)
                .foregroundStyle(Theme.text)
                .lineLimit(1)

            Text(share.share, format: .percent.precision(.fractionLength(0)))
                .font(.dsCaption).bold()
                .monospacedDigit()
                .foregroundStyle(Theme.accentText)

            Spacer(minLength: 8)

            MoneyText(share.planned, font: .dsSubhead, color: Theme.textSecondary)
                .layoutPriority(1)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(share.groupName)
        .accessibilityValue("\(share.planned.formattedIDR()), \(Int((share.share * 100).rounded())) percent of income")
    }

    private var tint: Color {
        Theme.categoryTint(hex: share.colorHex, seed: share.groupName)
    }
}
