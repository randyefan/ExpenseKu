//
//  PlanFixedRow.swift
//  ExpenseKu
//
//  One Fixed plan item: money standing for a single transaction the owner intends to
//  make.
//
//  Two lines, not one. An IDR amount and a row of chips cannot share 402pt — the
//  amounts here run to eight digits — so the name and the figure take the top line and
//  the chips take the full width beneath (PRD §6.2).
//
//  When the item has posted at a different figure than planned, the planned one is
//  shown alongside. Both amounts exist precisely so that comparison is possible — it
//  is the one thing the spreadsheet could never do (ADR-0005).
//
//  The Done control is a **sibling** of the tappable body, not nested inside it. A
//  Button inside another Button's label collapses into one accessibility element with
//  the inner one demoted to a custom action — which is what `idb ui describe-all`
//  reported, and it means the check cannot be tapped on its own. IncomeRow already had
//  the right shape; this follows it.
//

import SwiftUI

struct PlanFixedRow: View {
    let item: PlanItem
    let cycle: PayCycle
    let today: Date
    let calendar: Calendar
    let onTapCheck: () -> Void
    let onSelect: () -> Void

    private var state: DoneCheckState { .state(for: item) }

    private var actual: Expense? { item.linkedExpense }

    private var hasDrifted: Bool {
        guard let actual else { return false }
        return actual.amount != item.amount
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            DoneCheck(state: state, itemName: item.name, onTap: onTapCheck)
                .padding(.top, 1)

            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(item.name.isEmpty ? "Untitled" : item.name)
                            .font(.dsBody).bold()
                            .foregroundStyle(Theme.text)
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        MoneyText(actual?.amount ?? item.amount, font: .dsBody, color: Theme.text)
                            .layoutPriority(1)
                    }

                    chips

                    if hasDrifted {
                        Text("plan was \(item.amount.formattedIDR())")
                            .font(.dsCaption)
                            .monospacedDigit()
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(.pressableRow)
        }
        .padding(.vertical, 10)
    }

    /// A plain HStack, never a ChipRail: that is a horizontal ScrollView, and a scroll
    /// view inside a List row swallows the row's tap and kills the press wash.
    @ViewBuilder
    private var chips: some View {
        HStack(spacing: 6) {
            if let category = item.category {
                PlanChip(kind: .category(tint: Theme.categoryTint(hex: category.colorHex, seed: category.name)),
                         text: category.name,
                         symbol: category.resolvedSymbol)
            }
            if let account = item.account {
                PlanChip(kind: .account, text: account.name, symbol: account.resolvedSymbol)
            }
            if let dueDay = item.dueDay {
                let label = DueDay.label(day: dueDay, in: cycle, today: today, calendar: calendar)
                PlanChip(kind: label.isSoon ? .dueSoon : .due, text: label.text)
            }
            if item.isAuto {
                PlanChip(kind: .auto, text: "Auto", symbol: "bolt.fill")
            }
            if actual?.needsReview == true {
                PlanChip(kind: .review, text: "Review")
            }
            Spacer(minLength: 0)
        }
        .lineLimit(1)
    }
}
