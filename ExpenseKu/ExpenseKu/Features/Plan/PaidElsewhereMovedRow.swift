//
//  PaidElsewhereMovedRow.swift
//  ExpenseKu
//
//  One expense already moved on a Move from Jago sheet (docs/prd/paid-elsewhere.md §4.5,
//  AE5–AE6). The row is the label of a Menu, as on the transfer sheet, so a stray tap
//  while scrolling changes nothing; the ⋯ only marks it.
//

import SwiftUI

struct PaidElsewhereMovedRow: View {
    let member: PaidElsewhereMember
    let onUndo: () -> Void

    var body: some View {
        Menu {
            Button(action: onUndo) {
                Text(FundMenuEntry.notMoved.title)
                Text("Back to To move")
                Image(systemName: FundMenuEntry.notMoved.systemImage)
            }
        } label: {
            HStack(spacing: 12) {
                DoneCheckFace(state: .done)
                    .frame(width: 30, height: 30)
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
                MoneyText(member.amount, font: .dsBody, color: Theme.textSecondary)
                    .layoutPriority(1)
                Image(systemName: "ellipsis")
                    .font(.dsCaption.weight(.bold))
                    .foregroundStyle(Theme.textSecondary.opacity(0.7))
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(.pressableRow)
        .accessibilityLabel(member.name)
        .accessibilityValue("Moved, \(member.amount.formattedIDR())")
    }
}
