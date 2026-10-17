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
//  Money that reached it from earlier cycles — expenses paid early into it, and money set
//  aside for it (set-aside.md §4.6) — gets one caption under the legend, and the planned
//  amount gains a line saying what this cycle still puts in. The split is the detail's
//  job, never the row's: two captions read as too busy.
//
//  ＋ beside the bar is `EnvelopeAddMenu` (envelope-assignment.md §4.5). It is a sibling
//  of the row's Button rather than inside it, for the same accessibility reason as the
//  lead glyph.
//
//  A tap on the body opens the envelope's detail, not its editor (envelope-detail.md
//  §4.1): which expenses make up the bar is the question an envelope is opened to answer.
//

import SwiftUI

struct PlanEnvelopeRow: View {
    let item: PlanItem
    let progress: EnvelopeProgress?
    var fromEarlierCaption: String? = nil
    var ownShareCaption: String? = nil
    let onChooseFunding: (FundMenuEntry) -> Void
    let onSelect: () -> Void
    let onAddExpense: () -> Void
    let onMoveExpenses: () -> Void

    private let addSize = EnvelopeAddMenu.size

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

                        VStack(alignment: .trailing, spacing: 2) {
                            MoneyText(item.amount, font: .dsBody, color: Theme.text)
                            if let ownShareCaption {
                                Text(ownShareCaption)
                                    .font(.dsCaption)
                                    .monospacedDigit()
                                    .foregroundStyle(Theme.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                        .layoutPriority(1)
                    }

                    if let account = item.account {
                        HStack(spacing: 6) {
                            PlanChip(kind: .account, text: account.name, symbol: account.chipSymbol)
                            Spacer(minLength: 0)
                            if PlanItemState.of(item) == .funded {
                                FundedPlace(account: account.name)
                            }
                        }
                        .lineLimit(1)
                    }

                    HStack(spacing: 12) {
                        if let progress {
                            EnvelopeBar(progress: progress)
                        } else {
                            categoryNames
                        }
                        Color.clear.frame(width: addSize, height: 1)
                    }
                    .alignmentGuide(.envelopeBarLine) { $0[.bottom] }

                    if let fromEarlierCaption {
                        FromEarlierCaption(text: fromEarlierCaption)
                            .padding(.trailing, addSize + 12)
                            .padding(.top, -4)
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(.pressableRow)
            .accessibilityHint("Shows its expenses")
        }
        .overlay(alignment: Alignment(horizontal: .trailing, vertical: .envelopeBarLine)) {
            EnvelopeAddMenu(name: item.name, onAddExpense: onAddExpense, onMoveExpenses: onMoveExpenses)
        }
        .padding(.vertical, 10)
    }

    /// Before any expense lands there is no bar worth drawing, so the row says what it
    /// is going to total instead.
    private var categoryNames: some View {
        Text(EnvelopeDetail.claimsLine(for: item))
            .font(.dsCaption)
            .foregroundStyle(Theme.textSecondary)
            .lineLimit(1)
    }
}
