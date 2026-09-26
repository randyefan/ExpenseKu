//
//  PlanEnvelopeRow.swift
//  ExpenseKu
//
//  One Envelope: an allowance across many small purchases, totalling itself from
//  expenses the owner already logged.
//
//  Its lead glyph is inert — an envelope is never ticked — and is kept out of the
//  tappable body for the same reason PlanFixedRow does: a nested Button collapses the
//  row into one accessibility element.
//
//  It never creates an Expense, so its second line is the bar rather than chips. That bar going live during a cycle is
//  the single biggest improvement over the spreadsheet, where the same column was
//  added up by hand at the end of the month.
//
//  An envelope with an Account (§7.6) gains one chip line above the bar naming it, and
//  "in Jago" once the allowance is moved. Without one the row is exactly as before.
//

import SwiftUI

struct PlanEnvelopeRow: View {
    let item: PlanItem
    let progress: EnvelopeProgress?
    let onChooseFunding: (FundMenuEntry) -> Void
    let onSelect: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            DoneCheck(state: .state(for: item), tap: .of(item), itemName: item.name,
                      accountName: item.account?.name,
                      onTap: {}, onChoose: onChooseFunding)
                .padding(.top, 1)

            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(item.name.isEmpty ? "Untitled" : item.name)
                            .font(.dsBody).bold()
                            .foregroundStyle(Theme.text)
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        MoneyText(item.amount, font: .dsBody, color: Theme.text)
                            .layoutPriority(1)
                    }

                    if let account = item.account {
                        HStack(spacing: 6) {
                            PlanChip(kind: .account, text: account.name, symbol: account.resolvedSymbol)
                            Spacer(minLength: 0)
                            if PlanItemState.of(item) == .funded {
                                FundedPlace(account: account.name)
                            }
                        }
                        .lineLimit(1)
                    }

                    if let progress {
                        EnvelopeBar(progress: progress)
                    } else {
                        categoryNames
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(.pressableRow)
        }
        .padding(.vertical, 10)
    }

    /// Before any expense lands there is no bar worth drawing, so the row says what it
    /// is going to total instead.
    @ViewBuilder
    private var categoryNames: some View {
        let names = (item.envelopeCategories ?? []).map(\.name).sorted()
        Text(names.isEmpty ? "No categories yet" : names.joined(separator: " · "))
            .font(.dsCaption)
            .foregroundStyle(Theme.textSecondary)
            .lineLimit(1)
    }
}
