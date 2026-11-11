//
//  LookBackActionPill.swift
//  ExpenseKu
//
//  The trailing control of a Look back row (look-back.md §6, frames AB2–AB4): + Add in
//  DormantRow's Activate style, ▾ when it opens a menu, Wake, and the green ✓ that
//  undoes what was done.
//

import SwiftUI

struct LookBackActionPill: View {
    enum Style {
        case add
        case addMenu
        case wake
        case done(String)
    }

    let style: Style

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.caption2.bold())
            Text(title)
                .font(.dsCaption).bold()
            if case .addMenu = style {
                Image(systemName: "chevron.down")
                    .font(.caption2.bold())
            }
        }
        .foregroundStyle(isDone ? Theme.positive : Theme.accentText)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isDone ? Theme.surface : Theme.accent.opacity(Theme.tintFillOpacity), in: .capsule)
        .fixedSize()
    }

    private var isDone: Bool {
        if case .done = style { return true }
        return false
    }

    private var symbol: String {
        switch style {
        case .add, .addMenu: "plus"
        case .wake: "sun.max"
        case .done: "checkmark"
        }
    }

    private var title: String {
        switch style {
        case .add, .addMenu: AppLocalization.string(.add)
        case .wake: AppLocalization.string(.wake)
        case .done(let label): label
        }
    }
}
