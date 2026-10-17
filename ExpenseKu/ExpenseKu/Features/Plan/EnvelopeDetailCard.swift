//
//  EnvelopeDetailCard.swift
//  ExpenseKu
//
//  The top of an envelope's detail (envelope-detail.md §4.3, frame T2): the row the owner
//  tapped, restated — spent of planned, the same bar, legend, ＋ and from-earlier caption —
//  plus the one thing the row leaves out, what the envelope claims by itself.
//
//  Every figure is the cycle's `EnvelopeProgress`, the value that draws the row, so the
//  card cannot disagree with the row it was opened from.
//

import SwiftUI

struct EnvelopeDetailCard: View {
    let envelope: PlanItem
    let progress: EnvelopeProgress
    let fromEarlierCaption: String?
    let onAddExpense: () -> Void
    let onMoveExpenses: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                MoneyText(progress.spent, font: .dsLargeTitle.bold(), color: Theme.text)
                Text("spent of \(progress.planned.formattedIDR())")
                    .font(.dsSubhead)
                    .foregroundStyle(Theme.textSecondary)
            }
            .accessibilityElement(children: .combine)

            if let account = envelope.account {
                HStack(spacing: 6) {
                    PlanChip(kind: .account, text: account.name, symbol: account.chipSymbol)
                    Spacer(minLength: 0)
                    if PlanItemState.of(envelope) == .funded {
                        FundedPlace(account: account.name)
                    }
                }
                .lineLimit(1)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    EnvelopeBar(progress: progress)
                    Color.clear.frame(width: EnvelopeAddMenu.size, height: 1)
                }
                .alignmentGuide(.envelopeBarLine) { $0[.bottom] }

                if let fromEarlierCaption {
                    FromEarlierCaption(text: fromEarlierCaption)
                        .padding(.trailing, EnvelopeAddMenu.size + 12)
                }
            }
            .padding(.top, 6)
            .overlay(alignment: Alignment(horizontal: .trailing, vertical: .envelopeBarLine)) {
                EnvelopeAddMenu(name: envelope.name, onAddExpense: onAddExpense, onMoveExpenses: onMoveExpenses)
            }

            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)
                .padding(.vertical, 4)

            Text(EnvelopeDetail.claimsLine(for: envelope))
                .font(.dsSubhead)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
