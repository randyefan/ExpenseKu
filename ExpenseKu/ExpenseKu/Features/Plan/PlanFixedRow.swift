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
    let onChooseFunding: (FundMenuEntry) -> Void
    let onSelect: () -> Void

    @Environment(\.planRowsShowAccount) private var showsAccount

    private var state: DoneCheckState { .state(for: item) }

    private var actual: Expense? { item.linkedExpense }

    private var hasDrifted: Bool {
        guard let actual else { return false }
        return actual.amount != item.amount
    }

    var body: some View {
        HStack(alignment: .planRowTitleLine, spacing: 12) {
            DoneCheck(state: state, tap: .of(item), itemName: item.name,
                      accountName: item.account?.name,
                      onTap: onTapCheck, onChoose: onChooseFunding)
                .padding(.top, 1)

            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                        Text(item.name.isEmpty ? "Untitled" : item.name)
                            .font(.dsBody).bold()
                            .foregroundStyle(Theme.text)
                            .lineLimit(1)
                            .alignmentGuide(.planRowTitleLine) { $0[.top] }

                        Spacer(minLength: 8)

                        VStack(alignment: .trailing, spacing: 2) {
                            if hasDrifted {
                                Text("plan was \(item.amount.formattedIDR())")
                                    .font(.dsCaption)
                                    .monospacedDigit()
                                    .foregroundStyle(Theme.textSecondary)
                                    .lineLimit(1)
                            }

                            MoneyText(actual?.amount ?? item.amount, font: .dsBody, color: Theme.text)
                        }
                        .layoutPriority(1)
                    }

                    chips
                }
                .contentShape(.rect)
            }
            .buttonStyle(.pressableRow)
        }
        .padding(.vertical, 10)
    }

    /// A plain HStack, never a ChipRail: that is a horizontal ScrollView, and a scroll
    /// view inside a List row swallows the row's tap and kills the press wash. A line too
    /// long for the row first drops the Account chip's name (bank-logos.md §5.6.3).
    private var chips: some View {
        ViewThatFits(in: .horizontal) {
            chipLine(showsAccountName: true)
            chipLine(showsAccountName: false)
        }
    }

    private func chipLine(showsAccountName: Bool) -> some View {
        HStack(spacing: 6) {
            if let category = item.category {
                PlanChip(kind: .category(tint: Theme.categoryTint(hex: category.colorHex, seed: category.name)),
                         text: category.name,
                         symbol: category.resolvedSymbol)
            }
            if showsAccount, let account = item.account {
                PlanAccountChip(account: account, showsName: showsAccountName)
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
            if showsAccount, PlanItemState.of(item) == .funded, let account = item.account {
                FundedPlace(account: account.name)
            }
        }
        .lineLimit(1)
    }
}
