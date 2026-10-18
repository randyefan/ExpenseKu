//
//  PlanSetAsideRow.swift
//  ExpenseKu
//
//  One set-aside line: planned money this cycle sends to an envelope of a later plan
//  (docs/prd/set-aside.md §4.3, frame W1). "→ Jepang · Dec" — the paid-early tag's
//  glyph and month rule, because it is the same direction of travel.
//
//  It has no name of its own; the title is always the target's, so renaming the
//  envelope renames the line. Without a valid target (§4.9) it says so in the warning
//  colour, and still counts in this plan's Total cost.
//
//  The check is a sibling of the body for the reason PlanFixedRow gives: a Button nested
//  in another collapses into one accessibility element.
//

import SwiftUI

struct PlanSetAsideRow: View {
    let item: PlanItem
    let payday: Int
    let calendar: Calendar
    let onChooseFunding: (FundMenuEntry) -> Void
    let onSelect: () -> Void

    @Environment(\.planRowsShowAccount) private var showsAccount

    private var target: PlanItem? { SetAside.target(of: item) }
    private var label: PaidEarlyLabel? { SetAside.label(of: item, payday: payday, calendar: calendar) }

    var body: some View {
        HStack(alignment: .planRowTitleLine, spacing: 12) {
            DoneCheck(state: .state(for: item), tap: .of(item), itemName: spokenName,
                      accountName: item.account?.name,
                      onTap: {}, onChoose: onChooseFunding)
                .padding(.top, 1)

            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                        title
                            .alignmentGuide(.planRowTitleLine) { $0[.top] }
                            .layoutPriority(-1)
                        Spacer(minLength: 8)
                        MoneyText(item.amount, font: .dsBody, color: Theme.text)
                            .fixedSize()
                    }

                    HStack(spacing: 6) {
                        if target == nil {
                            Text("Pick an envelope")
                                .font(.dsCaption).bold()
                                .foregroundStyle(Theme.negative)
                        } else {
                            Text("Set aside")
                                .font(.dsCaption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        if showsAccount, let account = item.account {
                            PlanAccountChip(account: account)
                        }
                        Spacer(minLength: 0)
                    }
                    .lineLimit(1)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.pressableRow)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(spokenRow)
            .accessibilityAddTraits(.isButton)
        }
        .padding(.vertical, 10)
    }

    private var title: some View {
        HStack(spacing: 6) {
            Image(systemName: target == nil ? "exclamationmark.triangle.fill" : "arrow.forward")
                .font(.dsCaption.weight(.semibold))
                .foregroundStyle(target == nil ? Theme.negative : Theme.plan)
                .accessibilityHidden(true)
            Text(target.map(EnvelopeDetail.displayName(of:)) ?? "No envelope")
                .font(.dsBody).bold()
                .foregroundStyle(Theme.text)
                .lineLimit(1)
            if let label {
                Text("· \(label.short)")
                    .font(.dsBody)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
    }

    private var spokenRow: String {
        [spokenName, item.amount.formattedIDR(), target == nil ? "Pick an envelope" : nil, item.account?.name]
            .compactMap(\.self).joined(separator: ", ")
    }

    private var spokenName: String {
        guard let target, let label else { return "Set aside, no envelope" }
        return "Set aside for \(EnvelopeDetail.displayName(of: target)), \(label.long)"
    }
}
