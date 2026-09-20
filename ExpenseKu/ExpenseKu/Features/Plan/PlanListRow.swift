//
//  PlanListRow.swift
//  ExpenseKu
//
//  The list chrome every plan row sits in: the card fill, the hairline separator and
//  the press wash. The same shape as ExpenseListRow, and deliberately a separate type
//  rather than a reuse of it — the two must not converge, because a plan row's content
//  is a checklist and an expense row's is the ledger.
//

import SwiftUI

struct PlanListRow<Content: View>: View {
    var onSelect: (() -> Void)?
    @ViewBuilder let content: Content

    var body: some View {
        rowBody
            .listRowBackground(Theme.card)
            .listRowSeparatorTint(Theme.hairline)
            .listRowInsets(EdgeInsets(
                top: 0, leading: Metric.cardPadding,
                bottom: 0, trailing: Metric.cardPadding
            ))
    }

    @ViewBuilder
    private var rowBody: some View {
        if let onSelect {
            Button(action: onSelect) {
                content.contentShape(.rect)
            }
            .buttonStyle(.pressableRow)
        } else {
            content
        }
    }
}
