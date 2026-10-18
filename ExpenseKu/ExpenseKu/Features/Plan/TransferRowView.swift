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

import SwiftUI

struct TransferRowView: View {
    let row: TransferRow
    let onToggleTransferred: () -> Void
    let onEditAdjustment: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: onToggleTransferred) {
                Image(systemName: row.hasTransferred ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(row.hasTransferred ? Theme.accent : Theme.textSecondary.opacity(0.6))
                    .frame(width: 30, height: 30)
                    .contentShape(.circle)
            }
            .buttonStyle(.pressableCard)
            .accessibilityLabel("Transfer to \(row.accountName)")
            .accessibilityValue(row.hasTransferred ? "Sent" : "Not sent")
            .accessibilityAddTraits(row.hasTransferred ? [.isButton, .isSelected] : .isButton)

            Button(action: onEditAdjustment) {
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
                .contentShape(.rect)
            }
            .buttonStyle(.pressableRow)
        }
        .padding(.vertical, 8)
    }
}
