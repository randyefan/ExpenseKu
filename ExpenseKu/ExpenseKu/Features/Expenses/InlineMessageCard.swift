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
    var actionTitle: String? = nil
    var action: () -> Void = {}

    init(title: String, detail: String, actionTitle: String? = nil, action: @escaping () -> Void = {}) {
        self.title = title
        self.detail = detail
        self.actionTitle = actionTitle
        self.action = action
    }

    init(_ notice: EmptyNotice, onClearFilters: @escaping () -> Void) {
        self.init(title: notice.title, detail: notice.detail,
                  actionTitle: notice.offersClearFilters ? "Clear Filters" : nil,
                  action: onClearFilters)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.dsBody).fontWeight(.semibold)
                .foregroundStyle(Theme.text)
            Text(detail)
                .font(.dsSubhead)
                .foregroundStyle(Theme.textSecondary)
            if let actionTitle {
                Button(actionTitle, action: action)
                    .font(.dsSubhead.weight(.semibold))
                    .tint(Theme.accent)
                    .buttonStyle(.glass)
                    .padding(.top, 8)
            }
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
