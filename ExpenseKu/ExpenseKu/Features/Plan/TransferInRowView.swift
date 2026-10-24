//
//  TransferInRowView.swift
//  ExpenseKu
//
//  One item already in the line's Account (partial-transfer.md §6.1, AD5–AD7). A Funded
//  row is the label of a Menu, so a stray tap while scrolling changes nothing (§7.6);
//  the ⋯ only marks it, and the whole row is the target. A Done row has no Menu:
//  undoing Done deletes an Expense, which stays on the item's own check (I4).
//

import SwiftUI

struct TransferInRowView: View {
    let member: TransferMember
    let accountName: String
    let onUndo: (FundMenuEntry) -> Void

    var body: some View {
        if let entry = member.undoEntry {
            Menu {
                Button { onUndo(entry) } label: {
                    Text(entry.title)
                    Text("Back to To send")
                    Image(systemName: entry.systemImage)
                }
            } label: {
                content(showsMore: true)
            }
            .buttonStyle(.pressableRow)
            .accessibilityLabel(member.name)
            .accessibilityValue("\(member.inCaption(accountName: accountName)), \(member.amount.formattedIDR())")
        } else {
            content(showsMore: false)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(member.name)
                .accessibilityValue("\(member.inCaption(accountName: accountName)), \(member.amount.formattedIDR())")
        }
    }

    private func content(showsMore: Bool) -> some View {
        HStack(spacing: 12) {
            DoneCheckFace(state: member.check)
                .frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(member.name)
                    .font(.dsBody).bold()
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                Text(member.inCaption(accountName: accountName))
                    .font(.dsCaption)
                    .foregroundStyle(member.undoEntry == nil ? Theme.textSecondary : Theme.accentText)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            MoneyText(member.amount, font: .dsBody, color: Theme.textSecondary)
                .layoutPriority(1)
            if showsMore {
                Image(systemName: "ellipsis")
                    .font(.dsCaption.weight(.bold))
                    .foregroundStyle(Theme.textSecondary.opacity(0.7))
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 12)
        .contentShape(.rect)
    }
}
