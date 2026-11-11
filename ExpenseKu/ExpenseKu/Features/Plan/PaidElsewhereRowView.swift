//
//  PaidElsewhereRowView.swift
//  ExpenseKu
//
//  One Account in an envelope's PAID ELSEWHERE section (docs/prd/paid-elsewhere.md §4.3,
//  frame AE1), drawn like a transfer line: the check read off its expenses, the plate,
//  the Account's whole total, and what is left to move from the envelope's Account. The
//  whole row opens its sheet; the check is not a control of its own.
//

import SwiftUI

struct PaidElsewhereRowView: View {
    let row: PaidElsewhereRow
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
                            MoneyText(row.total, font: .dsBody, color: Theme.text)
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
        .accessibilityLabel(AppLocalization.string(.paidWith(row.accountName)))
        .accessibilityValue("\(row.caption), \(row.total.formattedIDR())")
        .accessibilityAddTraits(row.fill == .allIn ? [.isButton, .isSelected] : .isButton)
    }
}
