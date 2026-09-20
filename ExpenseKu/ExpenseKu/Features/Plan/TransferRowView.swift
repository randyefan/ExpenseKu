//
//  TransferRowView.swift
//  ExpenseKu
//
//  One line of the payday checklist. The owner works down these with six banking apps
//  open, so the row says the account, the amount, and nothing that is not needed to
//  make one transfer.
//
//  An all-Auto account reads "keep this covered" rather than "send this": the line
//  does not mean "transfer this", it means "make sure this account holds enough for
//  the debit to clear" (ADR-0007). `ke BNI Rp 7.706.000` is an Auto row.
//

import SwiftUI

struct TransferRowView: View {
    let row: TransferRow
    let onToggleTransferred: () -> Void
    let onEditAdjustment: () -> Void

    var body: some View {
        HStack(spacing: 12) {
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
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ke \(row.accountName)")
                            .font(.dsBody).bold()
                            .foregroundStyle(Theme.text)
                            .lineLimit(1)
                        if let subtitle {
                            Text(subtitle)
                                .font(.dsCaption)
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 8)
                    MoneyText(row.transfer, font: .dsBody, color: Theme.text)
                        .layoutPriority(1)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.pressableRow)
        }
        .padding(.vertical, 8)
    }

    private var subtitle: String? {
        if row.hasAdjustment {
            return "\(row.adjustment.formattedIDR()) adjustment applied"
        }
        if row.allAuto {
            return "Auto debit — keep this covered"
        }
        return nil
    }
}
