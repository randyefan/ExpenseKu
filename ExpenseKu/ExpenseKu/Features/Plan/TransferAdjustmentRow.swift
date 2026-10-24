//
//  TransferAdjustmentRow.swift
//  ExpenseKu
//
//  The adjustment on a transfer line's sheet (partial-transfer.md §6.1). It opens I2,
//  which no longer has a tap of its own on the checklist. Once a round has gone, it
//  says it was taken with the first one (§5.3), so a figure that no longer includes it
//  is not a surprise.
//

import SwiftUI

struct TransferAdjustmentRow: View {
    let adjustment: Decimal
    let note: String?

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Adjustment")
                    .font(.dsBody)
                    .foregroundStyle(Theme.text)
                if let note {
                    Text(note)
                        .font(.dsCaption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer(minLength: 8)
            if adjustment == 0 {
                Text("None")
                    .font(.dsBody)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                MoneyText(adjustment, font: .dsBody, color: adjustment < 0 ? Theme.negative : Theme.text)
            }
            Image(systemName: "chevron.right")
                .font(.dsCaption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary.opacity(0.6))
                .accessibilityHidden(true)
        }
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
    }
}
