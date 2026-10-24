//
//  TransferPickRowView.swift
//  ExpenseKu
//
//  One item still to send on a transfer line's sheet (partial-transfer.md §6.1, AD2–AD3).
//  The selection circle is Select mode's, so choosing reads as choosing; the section
//  header keeps it apart from a ✓ Done. An unchosen row stays in place and greys its
//  amount, so the figure below visibly loses it.
//

import SwiftUI

struct TransferPickRowView: View {
    let member: TransferMember
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
                    if !member.caption.isEmpty {
                        Text(member.caption)
                            .font(.dsCaption)
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                    }
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
        .accessibilityValue("\(isChosen ? "Chosen" : "Not chosen"), \(member.amount.formattedIDR())")
        .accessibilityAddTraits(isChosen ? [.isButton, .isSelected] : .isButton)
    }
}
