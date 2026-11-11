//
//  TransferRowView.swift
//  ExpenseKu
//
//  One line of the payday checklist. The owner works down these with six banking apps
//  open, so the row says the account, the amount, and nothing that is not needed to
//  make one transfer. The Account's plate leads it, the same one that heads its group
//  when the plan is sorted by Account, so a line and its group read as one
//  (bank-logos.md §5.6.4).
//
//  An all-Auto account reads "keep this covered" rather than "send this": the line
//  does not mean "transfer this", it means "make sure this account holds enough for
//  the debit to clear" (ADR-0007). BNI's Rp 7.706.000 is an Auto line.
//
//  The check reads off the line's items — nothing in, part in, all in — and is not a
//  control of its own: the whole line opens its sheet, where items are moved
//  (partial-transfer.md §5.1–§5.2).
//

import SwiftUI

struct TransferRowView: View {
    let row: TransferRow
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: row.fill.systemImage)
                    .font(.system(size: 22))
                    .foregroundStyle(row.fill == .nothingIn ? Theme.textSecondary.opacity(0.6) : Theme.accent)
                    .frame(width: 30, height: 30)
                HStack(alignment: .top, spacing: 8) {
                    AccountPlate(style: row.plate)
                        .padding(.top, 1)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(row.accountName)
                                .font(.dsBody).bold()
                                .foregroundStyle(Theme.text)
                                .lineLimit(1)
                            Spacer(minLength: 6)
                            MoneyText(row.transfer, font: .dsBody, color: Theme.text)
                                .layoutPriority(1)
                        }
                        Text(row.caption)
                            .font(.dsCaption)
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(2)
                    }
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.pressableRow)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(AppLocalization.string(.transferTo(row.accountName)))
        .accessibilityValue("\(row.fillDescription), \(row.transfer.formattedIDR())")
        .accessibilityAddTraits(row.isAllIn ? [.isButton, .isSelected] : .isButton)
    }
}
