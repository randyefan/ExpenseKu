//
//  TransferFigureRow.swift
//  ExpenseKu
//
//  The figure a transfer line's sheet ends on: "Transfer now", the number to type into
//  the banking app, or the line's "Total" once all of it is in (partial-transfer.md §6.1).
//

import SwiftUI

struct TransferFigureRow: View {
    let title: String
    let amount: Decimal
    let isNow: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.dsBody).bold()
                .foregroundStyle(Theme.text)
            Spacer(minLength: 8)
            MoneyText(amount, font: .dsHeadline, color: isNow ? Theme.accentText : Theme.text)
                .contentTransition(.numericText())
                .animation(Motion.snap, value: amount)
        }
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
    }
}
