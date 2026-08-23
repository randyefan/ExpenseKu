//
//  InlineMessageCard.swift
//  ExpenseKu
//
//  A quiet in-list message card — the counterpart of `EmptyStateView`, which is
//  full-bleed and so cannot sit inside a list row.
//

import SwiftUI

struct InlineMessageCard: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.dsBody).fontWeight(.semibold)
                .foregroundStyle(Theme.text)
            Text(detail)
                .font(.dsSubhead)
                .foregroundStyle(Theme.textSecondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .cardStyle()
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(
            top: 4, leading: Metric.screenPadding,
            bottom: 4, trailing: Metric.screenPadding
        ))
    }
}
