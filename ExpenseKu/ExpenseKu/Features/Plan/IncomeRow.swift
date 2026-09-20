//
//  IncomeRow.swift
//  ExpenseKu
//
//  One income line: a name, an amount, and whether it has arrived.
//
//  The tick is the whole interaction — on payday morning the owner works down these
//  as the money lands. Income exists only inside a plan (decision 6): it never becomes
//  an Expense, never reaches Insights, and creates no balance. Its only job is to give
//  Sisa a denominator.
//

import SwiftUI

struct IncomeRow: View {
    let line: IncomeLine
    let onToggleArrived: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggleArrived) {
                Image(systemName: line.hasArrived ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(line.hasArrived ? Theme.accent : Theme.textSecondary.opacity(0.6))
                    .frame(width: 30, height: 30)
                    .contentShape(.circle)
            }
            .buttonStyle(.pressableCard)
            .accessibilityLabel(line.name.isEmpty ? "Income line" : line.name)
            .accessibilityValue(line.hasArrived ? "Arrived" : "Not arrived yet")
            .accessibilityAddTraits(line.hasArrived ? [.isButton, .isSelected] : .isButton)

            Button(action: onEdit) {
                HStack(spacing: 8) {
                    Text(line.name.isEmpty ? "Untitled" : line.name)
                        .font(.dsBody)
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    MoneyText(line.amount, font: .dsBody, color: Theme.text)
                        .layoutPriority(1)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.pressableRow)
        }
        .padding(.vertical, 8)
    }
}
