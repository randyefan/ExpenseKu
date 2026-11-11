//
//  PaidElsewherePickRow.swift
//  ExpenseKu
//
//  One expense still to move on a Move from Jago sheet (docs/prd/paid-elsewhere.md §4.5,
//  AE2–AE3), the transfer sheet's choosing row: an unchosen expense stays in place and
//  greys its amount, so Move now visibly loses it.
//

import SwiftUI

struct PaidElsewherePickRow: View {
    let member: PaidElsewhereMember
    let isChosen: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                SelectionCircle(mark: isChosen ? .on : .off)
                VStack(alignment: .leading, spacing: 3) {
                    Text(member.name)
                        .font(.dsBody).bold()
                        .foregroundStyle(Theme.text)
                        .lineLimit(2)
                    Text(member.caption)
                        .font(.dsCaption)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                MoneyText(member.amount, font: .dsBody, color: isChosen ? Theme.text : Theme.textSecondary)
                    .layoutPriority(1)
            }
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(.pressableRow)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(member.name)
        .accessibilityValue("\(isChosen ? AppLocalization.string(.chosen) : AppLocalization.string(.notChosen)), \(member.amount.formattedIDR())")
        .accessibilityAddTraits(isChosen ? [.isButton, .isSelected] : .isButton)
    }
}
